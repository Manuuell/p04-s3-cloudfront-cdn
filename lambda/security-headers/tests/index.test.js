const { handler, SECURITY_HEADERS } = require('../index');

function buildEvent(existingHeaders = {}) {
  return {
    Records: [
      {
        cf: {
          response: {
            status: '200',
            headers: existingHeaders,
          },
        },
      },
    ],
  };
}

describe('security-headers Lambda@Edge', () => {
  test('agrega HSTS', async () => {
    const res = await handler(buildEvent());
    expect(res.headers['strict-transport-security'][0].value).toMatch(/max-age=\d+/);
  });

  test('agrega X-Content-Type-Options: nosniff', async () => {
    const res = await handler(buildEvent());
    expect(res.headers['x-content-type-options'][0].value).toBe('nosniff');
  });

  test('agrega X-Frame-Options: DENY', async () => {
    const res = await handler(buildEvent());
    expect(res.headers['x-frame-options'][0].value).toBe('DENY');
  });

  test('agrega Content-Security-Policy con default-src self', async () => {
    const res = await handler(buildEvent());
    expect(res.headers['content-security-policy'][0].value).toContain("default-src 'self'");
  });

  test('preserva headers existentes que no colisionan', async () => {
    const res = await handler(
      buildEvent({ 'cache-control': [{ key: 'Cache-Control', value: 'max-age=300' }] })
    );
    expect(res.headers['cache-control'][0].value).toBe('max-age=300');
  });

  test('sobrescribe headers de seguridad existentes con valores seguros', async () => {
    const res = await handler(
      buildEvent({ 'x-frame-options': [{ key: 'X-Frame-Options', value: 'ALLOWALL' }] })
    );
    expect(res.headers['x-frame-options'][0].value).toBe('DENY');
  });

  test('exporta todos los headers esperados', () => {
    expect(Object.keys(SECURITY_HEADERS)).toEqual(
      expect.arrayContaining([
        'strict-transport-security',
        'x-content-type-options',
        'x-frame-options',
        'referrer-policy',
        'content-security-policy',
        'permissions-policy',
      ])
    );
  });
});
