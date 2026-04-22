'use strict';

const SECURITY_HEADERS = {
  'strict-transport-security': [
    { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  ],
  'x-content-type-options': [
    { key: 'X-Content-Type-Options', value: 'nosniff' },
  ],
  'x-frame-options': [
    { key: 'X-Frame-Options', value: 'DENY' },
  ],
  'referrer-policy': [
    { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  ],
  'content-security-policy': [
    {
      key: 'Content-Security-Policy',
      value: [
        "default-src 'self'",
        "img-src 'self' data:",
        "script-src 'self'",
        "style-src 'self' 'unsafe-inline'",
        "object-src 'none'",
        "frame-ancestors 'none'",
        "base-uri 'self'",
      ].join('; '),
    },
  ],
  'permissions-policy': [
    { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
  ],
};

exports.handler = async (event) => {
  const response = event.Records[0].cf.response;
  response.headers = { ...response.headers, ...SECURITY_HEADERS };
  return response;
};

exports.SECURITY_HEADERS = SECURITY_HEADERS;
