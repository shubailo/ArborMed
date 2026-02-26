const logger = require('../../../src/utils/logger');

// Mock external dependencies
// Use virtual: true because node_modules might be incomplete in this environment
jest.mock(
  'resend',
  () => {
    return {
      Resend: jest.fn().mockImplementation(() => ({
        emails: {
          send: jest.fn(),
        },
      })),
    };
  },
  { virtual: true }
);

jest.mock('../../../src/utils/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  debug: jest.fn(),
}));

// We must require mailService AFTER mocking 'resend' if it's a top-level require
const mailService = require('../../../src/services/mailService');
const { Resend } = require('resend');

describe('MailService', () => {
  let originalEnv;

  beforeEach(() => {
    originalEnv = { ...process.env };
    jest.clearAllMocks();
  });

  afterEach(() => {
    process.env = originalEnv;
    // Reset configuration to default state
    if (mailService.init) mailService.init();
  });

  test('should initialize with Resend when SMTP_PASS starts with re_', () => {
    process.env.SMTP_PASS = 're_test_key';
    process.env.VERIFIED_SENDER = 'test@example.com';

    mailService.init();

    expect(mailService.isConfigured).toBe(true);
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('Configured with Resend API')
    );
  });

  test('should initialize in Mock Mode when SMTP_PASS is invalid', () => {
    delete process.env.SMTP_PASS;

    mailService.init();

    expect(mailService.isConfigured).toBe(false);
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('Mock Mode')
    );
  });

  test('sendOTP should log success via logger.info on successful send', async () => {
    process.env.SMTP_PASS = 're_test_key';
    const mockSend = jest
      .fn()
      .mockResolvedValue({ data: { id: 'msg_123' }, error: null });

    // We need to update the mock implementation for this specific test
    Resend.mockImplementation(() => ({
      emails: { send: mockSend },
    }));

    mailService.init();

    await mailService.sendOTP('test@example.com', '123456');

    expect(mockSend).toHaveBeenCalled();
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('Success! ID: msg_123')
    );
  });

  test('sendOTP fail-safe should log to logger.debug on API error', async () => {
    process.env.SMTP_PASS = 're_test_key';
    const mockSend = jest
      .fn()
      .mockResolvedValue({ data: null, error: { message: 'API Failed' } });

    Resend.mockImplementation(() => ({
      emails: { send: mockSend },
    }));

    mailService.init();

    // Expect it to throw the error
    await expect(
      mailService.sendOTP('test@example.com', '123456')
    ).rejects.toThrow();

    // Verify error logging
    expect(logger.error).toHaveBeenCalledWith(
      expect.stringContaining('CRITICAL FAILURE'),
      expect.any(String)
    );

    // Verify fail-safe logging (should be debug now)
    expect(logger.debug).toHaveBeenCalledWith(
      expect.stringContaining('FAIL-SAFE')
    );
    expect(logger.debug).toHaveBeenCalledWith(
      expect.stringContaining('123456')
    ); // The OTP
  });

  test('sendOTP in Mock Mode should log via logger.info', async () => {
    delete process.env.SMTP_PASS;
    mailService.init();

    await mailService.sendOTP('test@example.com', '654321');

    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('MOCK MODE')
    );
    expect(logger.info).toHaveBeenCalledWith(expect.stringContaining('654321'));
  });
});
