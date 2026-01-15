import 'dart:async';

import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';

class JobService {
  final int currentWorkerId = 1;

  Future<List<JobWorkflow>> getJobs() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      // ============ Job 1 ============
      JobWorkflow(
        id: 1,
        jobId: 101,
        status: JobStatus.ONGOING,
        steps: [
          JobStep(
            id: 1,
            name: "Inspection",
            description: "Initial inspection of machinery.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 2,
            name: "Repair Work",
            description: "Fix any broken parts.",
            orderIndex: 2,
            status: StepStatus.STARTED,
            assignedWorkerIds: [1],
            mockTimelineEvents: [
              TimelineEvent(
                username: "worker1",
                timestamp: DateTime.now().subtract(const Duration(hours: 2)),
                content: "Started repair work.",
              ),
              TimelineEvent(
                username: "manager",
                timestamp: DateTime.now().subtract(
                  const Duration(hours: 1, minutes: 30),
                ),
                content: "Check the safety valves.",
              ),
              TimelineEvent(
                username: "worker1",
                timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
                content: "valve_image.jpg",
                isAttachment: true,
              ),
            ],
          ),
          JobStep(
            id: 3,
            name: "Final Testing",
            description: "Ensure compliance and quality.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [1],
          ),
        ],
      ),

      // ============ Job 2 ============
      JobWorkflow(
        id: 2,
        jobId: 102,
        status: JobStatus.NOT_STARTED,
        steps: [
          JobStep(
            id: 4,
            name: "Inspection",
            description: "Check initial setup.",
            orderIndex: 1,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 5,
            name: "Repair Work",
            description: "Perform repairs as needed.",
            orderIndex: 2,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 6,
            name: "Final Inspection",
            description: "Finalize and report.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      // ============ Job 3 ============
      JobWorkflow(
        id: 3,
        jobId: 103,
        status: JobStatus.ONGOING,
        steps: [
          JobStep(
            id: 7,
            name: "Initial Assessment",
            description: "Assess damage and report findings.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 8,
            name: "Parts Replacement",
            description: "Replace broken parts with new ones.",
            orderIndex: 2,
            status: StepStatus.STARTED,
            assignedWorkerIds: [1],
            mockTimelineEvents: [
              TimelineEvent(
                username: "worker2",
                timestamp: DateTime.now().subtract(const Duration(hours: 3)),
                content: "Started parts replacement.",
              ),
            ],
          ),
          JobStep(
            id: 9,
            name: "Testing",
            description: "Perform functional tests.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [1],
          ),
          JobStep(
            id: 10,
            name: "Cleanup",
            description: "Clean up workspace.",
            orderIndex: 4,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      // ============ Job 4 ============
      JobWorkflow(
        id: 4,
        jobId: 104,
        status: JobStatus.COMPLETED,
        steps: [
          JobStep(
            id: 11,
            name: "Inspection",
            description: "Initial machine inspection.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 12,
            name: "Repair Work",
            description: "Performed repairs.",
            orderIndex: 2,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
            mockTimelineEvents: [
              TimelineEvent(
                username: "worker1",
                timestamp: DateTime.now().subtract(const Duration(days: 1)),
                content: "Replaced motor belt.",
              ),
              TimelineEvent(
                username: "worker1",
                timestamp: DateTime.now().subtract(const Duration(hours: 20)),
                content: "motor_belt_image.jpg",
                isAttachment: true,
              ),
            ],
          ),
          JobStep(
            id: 13,
            name: "Final Testing",
            description: "Tested machine successfully.",
            orderIndex: 3,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      // ============ Job 5 ============
      JobWorkflow(
        id: 5,
        jobId: 105,
        status: JobStatus.ONGOING,
        steps: [
          JobStep(
            id: 14,
            name: "Assessment",
            description: "Inspect electrical system.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 15,
            name: "Circuit Repair",
            description: "Repair broken circuits.",
            orderIndex: 2,
            status: StepStatus.STARTED,
            assignedWorkerIds: [1],
            mockTimelineEvents: [
              TimelineEvent(
                username: "worker1",
                timestamp: DateTime.now().subtract(const Duration(hours: 4)),
                content: "Found a short circuit at panel 3.",
              ),
            ],
          ),
          JobStep(
            id: 16,
            name: "Power Test",
            description: "Test restored power.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [1],
          ),
        ],
      ),

      // ============ Job 6 ============
      JobWorkflow(
        id: 6,
        jobId: 106,
        status: JobStatus.NOT_STARTED,
        steps: [
          JobStep(
            id: 17,
            name: "Inspection",
            description: "Check all machinery connections.",
            orderIndex: 1,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 18,
            name: "Lubrication",
            description: "Apply oil to moving parts.",
            orderIndex: 2,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 19,
            name: "Calibration",
            description: "Calibrate machinery sensors.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      // ============ Job 7 ============
      JobWorkflow(
        id: 7,
        jobId: 107,
        status: JobStatus.ONGOING,
        steps: [
          JobStep(
            id: 20,
            name: "Initial Check",
            description: "Check equipment status.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 21,
            name: "Repair",
            description: "Replace damaged components.",
            orderIndex: 2,
            status: StepStatus.STARTED,
            assignedWorkerIds: [1],
          ),
          JobStep(
            id: 22,
            name: "Testing",
            description: "Verify everything works.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [1],
          ),
          JobStep(
            id: 23,
            name: "Documentation",
            description: "Log results.",
            orderIndex: 4,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      // ============ Job 8 ============
      JobWorkflow(
        id: 8,
        jobId: 108,
        status: JobStatus.NOT_STARTED,
        steps: [
          JobStep(
            id: 24,
            name: "Inspection",
            description: "Initial site inspection.",
            orderIndex: 1,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 25,
            name: "Repair",
            description: "Repair site machinery.",
            orderIndex: 2,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 26,
            name: "Testing",
            description: "Ensure everything works.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      // ============ Job 9 ============
      JobWorkflow(
        id: 9,
        jobId: 109,
        status: JobStatus.COMPLETED,
        steps: [
          JobStep(
            id: 27,
            name: "Inspection",
            description: "Checked all systems.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 28,
            name: "Repair Work",
            description: "Fixed all issues.",
            orderIndex: 2,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 29,
            name: "Final Testing",
            description: "Verified final outcome.",
            orderIndex: 3,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      // ============ Job 10 ============
      JobWorkflow(
        id: 10,
        jobId: 110,
        status: JobStatus.ONGOING,
        steps: [
          JobStep(
            id: 30,
            name: "Inspection",
            description: "Initial inspection.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 31,
            name: "Repair Work",
            description: "Repair damaged parts.",
            orderIndex: 2,
            status: StepStatus.STARTED,
            assignedWorkerIds: [1],
          ),
          JobStep(
            id: 32,
            name: "Testing",
            description: "Test repaired units.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [1],
          ),
          JobStep(
            id: 33,
            name: "Final Cleanup",
            description: "Clean and finalize job.",
            orderIndex: 4,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
        ],
      ),

      JobWorkflow(
        id: 11,
        jobId: 111,
        status: JobStatus.PENDING, // <--- New Status
        steps: [
          JobStep(
            id: 34,
            name: "Emergency Assessment",
            description: "Assess critical failure immediately.",
            orderIndex: 1,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 35,
            name: "Resolution",
            description: "Resolve the issue.",
            orderIndex: 2,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [],
          ),
        ],
      ),
      // ============ NEW: Job 12 (With Pending Step) ============
      JobWorkflow(
        id: 12,
        jobId: 112,
        status: JobStatus.ONGOING,
        steps: [
          JobStep(
            id: 40,
            name: "Initial Diagnostic",
            description: "Run diagnostic tools.",
            orderIndex: 1,
            status: StepStatus.COMPLETED,
            assignedWorkerIds: [],
          ),
          JobStep(
            id: 41,
            name: "Order Parts",
            description: "Parts out of stock. Waiting for supplier.",
            orderIndex: 2,
            status: StepStatus.PENDING, // <--- RED Step
            assignedWorkerIds: [1],
          ),
          JobStep(
            id: 42,
            name: "Install Parts",
            description: "Install new parts once arrived.",
            orderIndex: 3,
            status: StepStatus.NOT_STARTED,
            assignedWorkerIds: [1],
          ),
        ],
      ),
    ];
  }
}
