-- 测试连接反馈可选附带的 HTTP 摘要。用户显式打开才有值。
-- 密钥和账单数字在客户端打码；这里只当一段字存。
ALTER TABLE feedback ADD COLUMN exchange TEXT;
