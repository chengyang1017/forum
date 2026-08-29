import 'dotenv/config';

import {
  cleanupExpiredChatMessages,
} from './cleanup_expired_chat_messages.js';

try {
  const result =
    await cleanupExpiredChatMessages();

  console.info(
    'Expired chat message cleanup completed:',
    result,
  );
} catch (error) {
  console.error(
    'Expired chat message cleanup failed:',
    error,
  );

  process.exitCode = 1;
}