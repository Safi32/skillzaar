import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';
import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

// Helper function to get FCM token for a user
async function getFCMTokenForUser(userId, userType) {
  try {
    const collection = userType === 'skilled_worker' ? 'SkilledWorkers' : 'JobPosters';
    const userDoc = await admin.firestore().collection(collection).doc(userId).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      return userData.fcmToken || null;
    }
    return null;
  } catch (error) {
    logger.error('Error getting FCM token for user', { userId, userType, error: String(error) });
    return null;
  }
}

// Helper function to send notification to specific user
async function sendNotificationToUser(fcmToken, title, body, data) {
  if (!fcmToken) return;

  try {
    const message = {
      notification: { title, body },
      data: { ...data, timestamp: Date.now().toString() },
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    logger.info('Notification sent successfully', { fcmToken: fcmToken.substring(0, 20) + '...', response });
  } catch (error) {
    logger.error('Failed to send notification', { fcmToken: fcmToken.substring(0, 20) + '...', error: String(error) });
  }
}

// New job posted - notify all skilled workers
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
      notification: { title, body },
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

// Job assigned by admin - notify both worker and job poster
export const onJobAssigned = onDocumentCreated('AssignedJobs/{assignedJobId}', async (event) => {
  try {
    const assignedJobId = event.params.assignedJobId;
    const assignedJob = event.data?.data() || {};

    const workerId = assignedJob.workerId;
    const jobPosterId = assignedJob.jobPosterId;
    const jobTitle = assignedJob.jobTitle || 'Job';
    const workerName = assignedJob.workerName || 'Worker';
    const jobPosterName = assignedJob.jobPosterName || 'Client';

    // Notify skilled worker
    const workerToken = await getFCMTokenForUser(workerId, 'skilled_worker');
    if (workerToken) {
      await sendNotificationToUser(
        workerToken,
        '🎉 Job Assigned!',
        `You have been assigned to: ${jobTitle}`,
        {
          type: 'job_assigned',
          assignedJobId,
          jobId: assignedJob.jobId || '',
          userType: 'skilled_worker',
        }
      );
    }

    // Notify job poster
    const posterToken = await getFCMTokenForUser(jobPosterId, 'job_poster');
    if (posterToken) {
      await sendNotificationToUser(
        posterToken,
        '✅ Worker Assigned!',
        `${workerName} has been assigned to your job: ${jobTitle}`,
        {
          type: 'job_assigned',
          assignedJobId,
          jobId: assignedJob.jobId || '',
          userType: 'job_poster',
        }
      );
    }

    logger.info('Job assignment notifications sent', { assignedJobId, workerId, jobPosterId });
  } catch (error) {
    logger.error('Failed sending job assignment notifications', { error: String(error) });
  }
});

// Job completed by job poster - notify skilled worker
export const onJobCompleted = onDocumentUpdated('AssignedJobs/{assignedJobId}', async (event) => {
  try {
    const assignedJobId = event.params.assignedJobId;
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data() || {};

    // Check if job was just completed
    const wasCompleted = beforeData.assignmentStatus !== 'completed' && afterData.assignmentStatus === 'completed';
    
    if (wasCompleted) {
      const workerId = afterData.workerId;
      const jobTitle = afterData.jobTitle || 'Job';
      const jobPosterName = afterData.jobPosterName || 'Client';

      // Notify skilled worker that job is completed and they need to rate
      const workerToken = await getFCMTokenForUser(workerId, 'skilled_worker');
      if (workerToken) {
        await sendNotificationToUser(
          workerToken,
          '⭐ Rate Your Client',
          `${jobPosterName} completed the job: ${jobTitle}. Please rate your experience.`,
          {
            type: 'job_completed',
            assignedJobId,
            jobId: afterData.jobId || '',
            userType: 'skilled_worker',
            action: 'rate_client',
          }
        );
      }

      logger.info('Job completion notification sent to worker', { assignedJobId, workerId });
    }
  } catch (error) {
    logger.error('Failed sending job completion notification', { error: String(error) });
  }
});

// Worker rating completed - notify job poster
export const onWorkerRatingCompleted = onDocumentUpdated('AssignedJobs/{assignedJobId}', async (event) => {
  try {
    const assignedJobId = event.params.assignedJobId;
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data() || {};

    // Check if worker rating was just completed
    const wasWorkerRatingCompleted = !beforeData.workerRatingCompleted && afterData.workerRatingCompleted;
    
    if (wasWorkerRatingCompleted) {
      const jobPosterId = afterData.jobPosterId;
      const jobTitle = afterData.jobTitle || 'Job';
      const workerName = afterData.workerName || 'Worker';

      // Notify job poster that worker has rated them
      const posterToken = await getFCMTokenForUser(jobPosterId, 'job_poster');
      if (posterToken) {
        await sendNotificationToUser(
          posterToken,
          '⭐ Rating Received',
          `${workerName} has rated your job: ${jobTitle}. Thank you for using our service!`,
          {
            type: 'worker_rating_completed',
            assignedJobId,
            jobId: afterData.jobId || '',
            userType: 'job_poster',
          }
        );
      }

      logger.info('Worker rating completion notification sent to job poster', { assignedJobId, jobPosterId });
    }
  } catch (error) {
    logger.error('Failed sending worker rating completion notification', { error: String(error) });
  }
});

// Job cancelled - notify both parties
export const onJobCancelled = onDocumentUpdated('AssignedJobs/{assignedJobId}', async (event) => {
  try {
    const assignedJobId = event.params.assignedJobId;
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data() || {};

    // Check if job was just cancelled
    const wasCancelled = beforeData.assignmentStatus !== 'cancelled' && afterData.assignmentStatus === 'cancelled';
    
    if (wasCancelled) {
      const workerId = afterData.workerId;
      const jobPosterId = afterData.jobPosterId;
      const jobTitle = afterData.jobTitle || 'Job';

      // Notify both parties
      const workerToken = await getFCMTokenForUser(workerId, 'skilled_worker');
      const posterToken = await getFCMTokenForUser(jobPosterId, 'job_poster');

      if (workerToken) {
        await sendNotificationToUser(
          workerToken,
          '❌ Job Cancelled',
          `The job "${jobTitle}" has been cancelled.`,
          {
            type: 'job_cancelled',
            assignedJobId,
            jobId: afterData.jobId || '',
            userType: 'skilled_worker',
          }
        );
      }

      if (posterToken) {
        await sendNotificationToUser(
          posterToken,
          '❌ Job Cancelled',
          `The job "${jobTitle}" has been cancelled.`,
          {
            type: 'job_cancelled',
            assignedJobId,
            jobId: afterData.jobId || '',
            userType: 'job_poster',
          }
        );
      }

      logger.info('Job cancellation notifications sent', { assignedJobId, workerId, jobPosterId });
    }
  } catch (error) {
    logger.error('Failed sending job cancellation notifications', { error: String(error) });
  }
});
