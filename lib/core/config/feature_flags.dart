// Feature flags for toggling runtime behaviors

// Toggle OTP-based authentication globally for both roles
// false => skip OTP (dev/testing), true => require OTP (staging/prod)
// Not const on purpose so both code paths are analyzed and imports remain used
bool kUseOtpAuth = false;
