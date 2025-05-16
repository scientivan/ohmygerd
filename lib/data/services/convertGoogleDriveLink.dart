String convertGoogleDriveLink(String originalLink) {
  final regExp = RegExp(r'd/([a-zA-Z0-9_-]+)');
  final match = regExp.firstMatch(originalLink);

  if (match != null) {
    final fileId = match.group(1);
    return 'https://drive.google.com/uc?export=view&id=$fileId';
  } else {
    return originalLink; // atau lempar error, tergantung kebutuhan
  }
}
