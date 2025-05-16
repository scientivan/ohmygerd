import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import { RunnableSequence } from "@langchain/core/runnables";
import { StringOutputParser } from "@langchain/core/output_parsers";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { HumanMessage, AIMessage, SystemMessage } from "@langchain/core/messages";
import axios from "axios";

import db from "../config/firestore.js";
import dotenv from 'dotenv'
if (process.env.NODE_ENV !== 'production') {
    try {
        dotenv.config();
    } catch (error) {
        console.error("Error loading environment variables:", error);
    }
}

const model = new ChatGoogleGenerativeAI({
    model : "gemini-2.0-flash",
    apiKey : process.env.GEMINI_API_KEY,
    maxOutputTokens : 2048
});


// Fungsi untuk scanning gambar makanan
export const scanPhotoWithGemini = async (buffer) => {
    try {
        // console.log(buffer)
        const base64Image = buffer.toString("base64");
        const messages = [
            {
              role: "user", 
              content: [
                {
                  type: "image_url",
                  image_url: {
                    url: `data:image/jpeg;base64,${base64Image}`,
                  }
                },
                {
                  type: "text",
                  text: `Tolong identifikasi makanan dalam gambar ini dan beri daftarnya dalam format JSON seperti:
                  {
                  "makanan": [
                      { "nama": "Nasi Putih", "status": "Sangat Aman" },
                      ...
                  ]
                  }
                  Analisis isi gambar dan identifikasi setiap komponen makanan yang terlihat, termasuk bahan utama dan topping jika ada. Uraikan makanan campuran menjadi bagian-bagian penyusunnya (misalnya: nasi goreng menjadi nasi, telur, ayam, cabai, dll). Jawab dengan format JSON dengan struktur nama komponen makanan dan statusnya (apakah sangat aman, masih aman, atau tidak aman untuk dikonsumsi oleh penderita gerd) dan jangan tambahkan kata apapun diluar itu. Jika tidak ada makanan yang terlihat, kembalikan response dengan kosong saja.`
                }
              ]
            }
          ];
      
        const response = await model.invoke(messages);
        let rawContent = response.content.trim();
        
        // ngilangin  ```json dan ```
        if (rawContent.startsWith("```json")) {
            rawContent = rawContent.replace(/^```json/, "").replace(/```$/, "").trim();
        }
        
        const parsed = JSON.parse(rawContent); 
        // { makanan: [] }
        // console.log(parsed) 
        // udah dikembalikan sebagai object JSON
        return parsed;
    } catch (error) {
        console.error("Error in scanPhotoWithGemini:", error);
        throw new Error(`Failed to scan food image: ${error.message}`);
    }
};

export const getRestaurantRecommendation = async (req, res) => {
  try {
    const { uid, mealName, position } = req.body;
    console.log('tesdt');
    
    // Check required fields
    if (!uid) return res.status(400).json({ error: "Missing uid data" });
    if (!mealName) return res.status(400).json({ error: "Missing meal name" });
    if (!position) return res.status(400).json({ error: "Missing position data" });
    
    try {
      // Split position and handle potential format issues
      const [latitude, longitude] = position.split(',').map(coord => parseFloat(coord.trim()));

      
      if (isNaN(latitude) || isNaN(longitude)) {
        return res.status(400).json({ error: "Invalid position format. Expected 'latitude, longitude'" });
      }
      
      console.log(`Searching for "${mealName}" near coordinates: ${latitude}, ${longitude}`);
      
      
      const nearbySearchUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latitude},${longitude}&keyword=${encodeURIComponent(mealName)}&type=restaurant&rankby=distance&key=${process.env.GOOGLE_API_KEY}`;
      
      console.log(`API Request URL: ${nearbySearchUrl.replace(process.env.GOOGLE_API_KEY, 'API_KEY_HIDDEN')}`);
      
      let response;
      try {
        response = await axios.get(nearbySearchUrl);
      } catch (axiosError) {
        console.error("Error fetching from Google Places API:", axiosError);
        throw new Error(`Google Places API request failed: ${axiosError.message}`);
      }
      
      if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
        console.error("Google Places API error status:", response.data.status);
        console.error("Error message:", response.data.error_message || "No detailed error message provided");
        console.log("Error with nearby search, trying text search as fallback");
        
        const textSearchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(`${mealName} near ${latitude},${longitude}`)}&key=${process.env.GOOGLE_API_KEY}`;
        
        try {
          const textSearchResponse = await axios.get(textSearchUrl);
          
          if (textSearchResponse.data.status === 'OK' && textSearchResponse.data.results && textSearchResponse.data.results.length > 0) {
            response.data.results = textSearchResponse.data.results;
            response.data.status = 'OK';
            console.log("Fallback search results found:", response.data.results.length);
          } else {
            console.log("No results found from fallback search either");
            return res.status(200).json([]);
          }
        } catch (fallbackErr) {
          console.error("Fallback search also failed:", fallbackErr);
          return res.status(500).json({ 
            error: "All search methods failed",
            detail: fallbackErr.message
          });
        }
      }
      
      console.log("Google Places API response status:", response.data.status);
      console.log("Total results found:", response.data.results ? response.data.results.length : 0);
      
      if (!response.data.results || response.data.results.length === 0) {
        console.log("No results found for the query");
        return res.status(200).json([]);
      }
      
      const results = response.data.results.map(place => {
        try {
          const placeLocation = place.geometry.location;
          const distance = calculateDistance(
            latitude, 
            longitude, 
            placeLocation.lat, 
            placeLocation.lng
          );
          
          return {
            ...place,
            distance: distance // Add distance to the place object
          };
        } catch (mapError) {
          console.error("Error processing place data:", mapError, place);
          // Return place without distance if calculation fails
          return {
            ...place,
            distance: Number.MAX_VALUE // Set a high distance so it appears last in sorting
          };
        }
      });
      
      // Sort results by distance (closest first)
      results.sort((a, b) => a.distance - b.distance);
      
      const closestResults = results.slice(0, 3);
      
      const parsed = closestResults.map(place => {
        try {
          return {
            name: place.name,
            address: place.formatted_address || place.vicinity || "Address not available",
            location: place.geometry.location,
            photo: place.photos?.[0]
              ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place.photos[0].photo_reference}&key=${process.env.GOOGLE_API_KEY}`
              : null,
            rating: place.rating || "No rating available",
            distance: {
              value: place.distance,
              text: `${(place.distance / 1000).toFixed(1)} km` // Convert to km with 1 decimal place
            },
            estimatedTime: `${Math.ceil(place.distance / 83.33)} menit`, // Assuming average walking speed of 5km/h (83.33m/min)
            place_id: place.place_id
          };
        } catch (parseError) {
          console.error("Error parsing place data:", parseError, place);
          // Return minimal place data if parsing fails
          return {
            name: place.name || "Unknown Place",
            address: place.vicinity || "Address not available",
            place_id: place.place_id || "Unknown ID",
            error: "Error parsing complete place data"
          };
        }
      });
      
      console.log(`Sending ${parsed.length} results to client`);
      return res.status(200).json(parsed);
    } catch (innerErr) {
      console.error("Inner processing error:", innerErr);
      return res.status(500).json({ 
        error: "Error processing restaurant recommendation data", 
        detail: innerErr.message
      });
    }
  } catch (err) {
    console.error("Error details:", err);
    return res.status(500).json({ 
      error: "Failed to fetch data from Google Places API", 
      detail: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
};

/**
 * Calculate distance between two coordinates using the Haversine formula
 * @param {number} lat1 - Latitude of first point
 * @param {number} lon1 - Longitude of first point
 * @param {number} lat2 - Latitude of second point
 * @param {number} lon2 - Longitude of second point
 * @returns {number} Distance in meters
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  try {
    // Earth's radius in meters
    const R = 6371000;
    
    // Convert latitude and longitude from degrees to radians
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);
    const radLat1 = toRadians(lat1);
    const radLat2 = toRadians(lat2);
    
    // Haversine formula
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(radLat1) * Math.cos(radLat2) * 
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    const distance = R * c;
    
    return distance;
  } catch (error) {
    console.error("Error calculating distance:", error);
    return 0; // Return 0 as fallback
  }
}

/**
 * Convert degrees to radians
 * @param {number} degrees - Angle in degrees
 * @returns {number} Angle in radians
 */
function toRadians(degrees) {
  try {
    return degrees * (Math.PI / 180);
  } catch (error) {
    console.error("Error converting to radians:", error);
    return 0; // Return 0 as fallback
  }
}



export const chatbotResponse = async (req, res) => {
  try {
    const { uid, question } = req.body;  // Ambil uid dan pertanyaan dari request

    if (!uid || !question) {
      return res.status(400).json({
        success: false,
        message: 'Missing required parameters (uid or question)'
      });
    }

    try {
      // 1. Load 5 chat terakhir
      const chatHistory = await loadChatHistory(uid);
      
      // 2. Ubah format chat history menjadi format yang didukung LangChain
      const formattedMessages = formatChatHistory(chatHistory);
      
      // 3. Buat prompt baru dengan SystemMessage
      const systemMessage = new SystemMessage("Kamu adalah asisten medis spesialis GERD. Jawab hanya topik GERD dan sakit perut. Kalau pertanyaan tidak relevan dengan topik tersebut, balas dengan: 'Maaf, saya hanya menjawab pertanyaan tentang GERD.'");
      
      // 4. Buat chain
      const chain = RunnableSequence.from([
          ChatPromptTemplate.fromMessages([
              systemMessage,
              ...formattedMessages,
              new HumanMessage(question)
          ]),
          model,
          new StringOutputParser(),
      ]);

      // 5. Invoke chain
      let response;
      try {
        response = await chain.invoke({});
      } catch (invokeError) {
        console.error("Error invoking LLM chain:", invokeError);
        return res.status(500).json({
          success: false,
          message: 'Failed to generate response from AI model',
          error: invokeError.message
        });
      }

      // 6. Save ke firestore
      try {
        await saveChatHistory(uid, question, response);
      } catch (saveError) {
        console.error("Error saving chat history:", saveError);
        // Continue despite save error - we still want to return response to user
      }
      
      // 7. Send ke frontend
      res.status(200).json({ response }); 
    } catch (innerError) {
      console.error('Error in chatbot processing:', innerError);
      res.status(500).json({
          success: false,
          message: 'Error processing chatbot request',
          error: innerError.message
      });
    }
  } catch (error) {
    console.error('Error generating response:', error);
    res.status(500).json({
        success: false,
        message: 'Gagal menghasilkan respons',
        error: error.message
    });
  }
};

export const getChatHistory = async (req, res) => {
  try {
    const { uid } = req.body;
    
    if (!uid) {
      return res.status(400).json({
        success: false,
        message: 'Missing required parameter (uid)'
      });
    }
    
    try {
      const chatHistory = await loadChatHistory(uid);
      
      // Kirim respons dalam format yang sesuai dengan yang diharapkan frontend
      res.status(200).json({
          success: true,
          chats: chatHistory
      });
    } catch (loadError) {
      console.error('Error loading chat history:', loadError);
      res.status(500).json({
          success: false,
          message: 'Gagal mengambil riwayat chat',
          error: loadError.message
      });
    }
  } catch (error) {
    console.error('Error getting chat history:', error);
    res.status(500).json({
        success: false,
        message: 'Gagal mengambil riwayat chat',
        error: error.message
    });
  }
};

// Fungsi untuk mengubah format chat history menjadi format yang didukung LangChain
const formatChatHistory = (chatHistory) => {
  try {
    const formattedMessages = [];
    
    for (const chat of chatHistory) {
      try {
        formattedMessages.push(new HumanMessage(chat.userMessage));
        formattedMessages.push(new AIMessage(chat.botResponse));
      } catch (chatError) {
        console.error("Error formatting chat message:", chatError, chat);
        // Skip problematic messages but continue processing others
      }
    }
    
    return formattedMessages;
  } catch (error) {
    console.error("Error formatting chat history:", error);
    return []; // Return empty array as fallback
  }
};

const saveChatHistory = async (uid, question, response) => {
  try {
    const userRef = db.collection('users').doc(uid).collection('chat_history').doc();
    await userRef.set({
        question,
        response,
        timestamp: new Date()
    });
  } catch (error) {
    console.error("Error saving chat history:", error);
    throw new Error(`Failed to save chat history: ${error.message}`);
  }
};

const loadChatHistory = async (uid) => {
  try {
    const chatHistoryRef = db.collection('users')
        .doc(uid)
        .collection('chat_history')
        .orderBy('timestamp', 'desc')
        .limit(5);

    let querySnapshot;
    try {
      querySnapshot = await chatHistoryRef.get();
    } catch (queryError) {
      console.error("Error querying chat history:", queryError);
      throw new Error(`Failed to query chat history: ${queryError.message}`);
    }

    const chats = [];

    querySnapshot.forEach(doc => {
      try {
        const { question, response, timestamp } = doc.data();
        chats.push({
            id: doc.id,
            userMessage: question,
            botResponse: response,
            timestamp: timestamp ? timestamp.toDate().toISOString() : new Date().toISOString()
        });
      } catch (docError) {
        console.error("Error processing chat document:", docError, doc.id);
        // Skip problematic documents but continue processing others
      }
    });

    // Reverse untuk mendapatkan urutan kronologis (dari yang lama ke baru)
    return chats.reverse();
  } catch (error) {
    console.error("Error loading chat history:", error);
    return []; // Return empty array as fallback
  }
};