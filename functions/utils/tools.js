const now = new Date();
const pad = (n) => String(n).padStart(2, '0');

const year = now.getFullYear();
const month = pad(now.getMonth() + 1); // getMonth() dari 0–11
const day = pad(now.getDate());

export const formatDate = () => {
    // Hasil: "2025-05-01"
    const docId = `${year}-${month}-${day}`;
    // console.log(docId)
    return docId;
}
export const formatDateForYesterday = () => {
    
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1)
    const year = yesterday.getFullYear();
    const month = String(yesterday.getMonth() + 1).padStart(2, '0');
    const day = String(yesterday.getDate()).padStart(2, '0');

    const docId = `${year}-${month}-${day}`;
    return docId;
}
export const formatMonthYear = () => {
    // Hasil: "2025-05"
    const docId = `${year}-${month}`;
    // console.log(docId)
    return docId;
}

export const parseMinutesFromTimeString = (timeString) => {
    if (!timeString || typeof timeString !== "string") return null;

    const [hoursStr, minutesStr] = timeString.split(":");
    const hours = parseInt(hoursStr, 10);
    const minutes = parseInt(minutesStr, 10);

    if (isNaN(hours) || isNaN(minutes)) return null;

    return (hours * 60) + minutes;
}


export const formatTime = () => {
    const hour = now.getHours();
    const minute = pad(now.getMinutes());
    const second = pad(now.getSeconds());
  
    // Hasil: "06-03-53"
    const docId = `${hour}-${minute}-${second}`;
    // console.log(docId)
    return docId;
  }