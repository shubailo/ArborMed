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
        host: 'smtp.gmail.com',
        port: 465,
        secure: true,
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
      '[API] Verification email delivery failed.'
    );
    expect(JSON.stringify(logger.debug.mock.calls)).not.toContain('123456');
  });

  test('missing transport rejects delivery without logging codes', async () => {
    delete process.env.SMTP_PASS;
    mailService.init();
    await expect(mailService.sendOTP('test@example.com', '654321')).rejects.toThrow();
    expect(JSON.stringify(logger.info.mock.calls)).not.toContain('654321');
  });
  test('an explicit SMTP server and port take precedence over the account suffix', () => {
    Object.assign(process.env, {SMTP_HOST:'smtp.example.test', SMTP_PORT:'587', SMTP_USER:'example@gmail.com', SMTP_PASS:'fixture'});
    mailService.init();
    const options = nodemailer.createTransport.mock.lastCall[0];
    expect(options).toMatchObject({host:'smtp.example.test', port:587, secure:false});
    expect(options.service).toBeUndefined();
  });

  test('a custom SMTP relay with resend in its hostname still uses SMTP', () => {
    Object.assign(process.env, { SMTP_HOST: 'resend-relay.example.test', SMTP_USER: 'relay', SMTP_PASS: 're_fixture' });
    mailService.init();
    expect(mailService.mode).toBe('smtp');
    expect(nodemailer.createTransport.mock.lastCall[0].host).toBe('resend-relay.example.test');
  });

  test('incomplete or invalid SMTP configuration is reported before accepting mail', () => {
    Object.assign(process.env, {SMTP_HOST:'smtp.example.test', SMTP_PASS:'fixture', SMTP_PORT:'587'});
    delete process.env.SMTP_USER;
    mailService.init();
    expect(mailService.isConfigured).toBe(false);
    process.env.SMTP_USER = 'relay-user';
    process.env.SMTP_PORT = '587abc';
    mailService.init();
    expect(mailService.isConfigured).toBe(false);
  });

  test('Resend cancels a stalled transport with the supplied deadline signal', async () => {
    delete process.env.SMTP_HOST;
    process.env.SMTP_PASS = 're_fixture';
    const abort = new AbortController();
    const timeout = jest.spyOn(AbortSignal, 'timeout').mockReturnValue(abort.signal);
    const send = jest.fn((_message, options) => {
      if (!options?.signal) throw new Error('missing cancellation signal');
      return new Promise((_, reject) => options.signal.addEventListener('abort', () => reject(new Error('deadline'))));
    });
    Resend.mockImplementation(() => ({emails:{send}}));
    try {
      mailService.init();
      const pending = expect(mailService.sendOTP('student@example.test', '123456')).rejects.toThrow();
      abort.abort();
      await pending;
      expect(timeout).toHaveBeenCalledWith(10000);
      expect(send.mock.calls[0][1].signal).toBe(abort.signal);
    } finally { timeout.mockRestore(); }
  });

  test.each(['resend', 'smtp'])('the %s failure log omits mailbox and raw provider text', async mode => {
    const email = 'learner@example.test';
    const raw = 'fixture-provider-detail';
    delete process.env.SMTP_HOST;
    process.env.SMTP_USER = 'relay@gmail.com';
    process.env.SMTP_PASS = mode === 'smtp' ? 'fixture' : 're_fixture';
    Resend.mockImplementation(() => ({ emails:{send:jest.fn().mockRejectedValue(new Error(raw))} }));
    nodemailer.createTransport.mockReturnValue({sendMail:jest.fn().mockRejectedValue(new Error(raw))});
    mailService.init();
    await expect(mailService.sendOTP(email, '123456')).rejects.toThrow();
    const logs = JSON.stringify([logger.info.mock.calls,logger.error.mock.calls]);
    for (const detail of [email,raw,'123456']) expect(logs).not.toContain(detail);
  });

  test('a verification email does not fetch its branding from a third party', async () => {
    delete process.env.SMTP_HOST;
    process.env.SMTP_PASS = 're_fixture';
    const send = jest.fn().mockResolvedValue({data:{id:'ok'}});
    Resend.mockImplementation(() => ({emails:{send}}));
    mailService.init();
    await mailService.sendOTP('student@example.test','123456');
    expect(send.mock.calls[0][0].html).not.toMatch(/<img[^>]+src=["']https?:/i);
  });

});
