String formatPhoneNumber(String input) {
  input = input.trim();
  if (input.startsWith('+')) {
    return input;
  }
  if (input.startsWith('0') && input.length == 11) {
    return '+92' + input.substring(1);
  }
  throw FormatException('Invalid phone number format');
}
