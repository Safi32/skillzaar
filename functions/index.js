import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';
import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}
 
export const onJobCreated = onDocumentCreated('Job/{jobId}', async (event) => {
  try {
    const jobId = event.params.jobId;
    const job = event.data?.data() || {};

    const title = `New Job Posted: ${job.title_en || 'New job'}`;
    const bodyParts = [];
    if (job.description_en) bodyParts.push(job.description_en);
    if (job.Location) bodyParts.push(`Location: ${job.Location}`);
    if (typeof job.price === 'number') bodyParts.push(`Budget: Rs ${Math.round(job.price)}`);
    const body = bodyParts.join('\n');

    const message = {
      notification: {
        title,
        body,
      },
      data: {
        jobId: String(jobId),
        type: 'job_posting',
        location: String(job.Location ?? ''),
        budget: String(job.price ?? ''),
      },
      topic: 'job_notifications',
    };

    const response = await admin.messaging().send(message);
    logger.info('Sent topic notification for new job', { jobId, response });
  } catch (error) {
    logger.error('Failed sending topic notification on job create', { error: String(error) });
  }
});
