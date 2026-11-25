const logger = require('../../../src/utils/logger');

// Mock external dependencies
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

jest.mock('nodemailer', () => ({
  createTransport: jest.fn().mockImplementation(() => ({
    sendMail: jest.fn().mockResolvedValue({ messageId: 'smtp_123' }),
  })),
}));

jest.mock('../../../src/utils/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  debug: jest.fn(),
}));

const mailService = require('../../../src/services/mailService');
const { Resend } = require('resend');
const nodemailer = require('nodemailer');

describe('MailService', () => {
  let originalEnv;

  beforeEach(() => {
    originalEnv = { ...process.env };
    jest.clearAllMocks();
  });

  afterEach(() => {
    process.env = originalEnv;
    if (mailService.init) mailService.init();
  });

  test('should initialize with Resend when SMTP_PASS starts with re_', () => {
    process.env.SMTP_PASS = 're_test_key';
    process.env.VERIFIED_SENDER = 'test@example.com';

    mailService.init();

    expect(mailService.isConfigured).toBe(true);
    expect(mailService.mode).toBe('resend');
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('Configured with Resend API')
    );
  });

  test('should initialize with SMTP when standard credentials are provided', () => {
    process.env.SMTP_USER = 'test@gmail.com';
    process.env.SMTP_PASS = 'my_app_password';

    mailService.init();

    expect(mailService.isConfigured).toBe(true);
    expect(mailService.mode).toBe('smtp');
    expect(nodemailer.createTransport).toHaveBeenCalledWith(
      expect.objectContaining({
        service: 'gmail',
        auth: {
          user: 'test@gmail.com',
          pass: 'my_app_password',
        },
      })
    );
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('Configured with SMTP')
    );
  });

  test('should disable email delivery when SMTP_PASS is missing', () => {
    delete process.env.SMTP_PASS;

    mailService.init();

    expect(mailService.isConfigured).toBe(false);
    expect(mailService.mode).toBe('disabled');
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('delivery is disabled')
    );
  });

  test('sendOTP should log success via logger.info on successful Resend send', async () => {
    process.env.SMTP_PASS = 're_test_key';
    const mockSend = jest
      .fn()
      .mockResolvedValue({ data: { id: 'msg_123' }, error: null });

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

  test('sendOTP should send via nodemailer when in SMTP mode', async () => {
    const mockSendMail = jest
      .fn()
      .mockResolvedValue({ messageId: 'smtp_success_1' });
    nodemailer.createTransport.mockReturnValue({
      sendMail: mockSendMail,
    });

    process.env.SMTP_USER = 'bot@gmail.com';
    process.env.SMTP_PASS = 'gmail_secret_app_pw';

    mailService.init();

    await mailService.sendOTP('user@example.com', '789123');

    expect(mockSendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'user@example.com',
        text: expect.stringContaining('789123'),
      })
    );
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('Success! Message ID: smtp_success_1')
    );
  });

  test('sendOTP reports delivery failure without logging the code', async () => {
    process.env.SMTP_PASS = 're_test_key';
    const mockSend = jest
      .fn()
      .mockResolvedValue({ data: null, error: { message: 'API Failed' } });

    Resend.mockImplementation(() => ({
      emails: { send: mockSend },
    }));

    mailService.init();

    await expect(
      mailService.sendOTP('test@example.com', '123456')
    ).rejects.toThrow();

    expect(logger.error).toHaveBeenCalledWith(
      expect.stringContaining('CRITICAL FAILURE'),
      expect.any(String)
    );
    expect(JSON.stringify(logger.debug.mock.calls)).not.toContain('123456');
  });

  test('missing transport rejects delivery without logging codes', async () => {
    delete process.env.SMTP_PASS;
    mailService.init();
    await expect(mailService.sendOTP('test@example.com', '654321')).rejects.toThrow();
    expect(JSON.stringify(logger.info.mock.calls)).not.toContain('654321');
  });
});
