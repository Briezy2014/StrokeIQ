import '../../core/constants/demo_account_constants.dart';
import '../../core/services/usa_motivational_standards_catalog.dart';
import '../../core/utils/swim_time.dart';
import '../../providers/swimmer_data_provider.dart';
import '../models/meet_result.dart';
import '../models/race_log.dart';
import '../models/swim_goal.dart';
import '../models/swim_pose_metrics.dart';
import '../models/swim_schedule_entry.dart';
import '../models/swimmer_profile.dart';
import '../models/video_models.dart';

/// Fully filled showcase athlete for coach demos (`demo@swimiqapp.com`).
///
/// Made-up but realistic competitive data for **Aspyn Briez** so every tab
/// (Dashboard, PBs, Log/Meets, Goals, Video Lab + AI feedback, Passport /
/// recruiting, SwimDNA, Dryland, Race Intelligence, cuts) looks complete.
abstract final class AspynBriezDemoSeed {
  static const swimmerName = DemoAccountConstants.athleteName;

  static bool shouldUse({String? swimmerKey, String? email}) {
    return DemoAccountConstants.isDemoEmail(email) ||
        DemoAccountConstants.isDemoSwimmerKey(swimmerKey);
  }

  static SwimmerData build({
    required UsaMotivationalStandardsCatalog motivationalStandards,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final profile = _profile();
    final meetResults = _meetResults();
    final raceLogs = _raceLogs(clock);
    final goals = _goals(clock);
    final schedules = _schedules(clock);
    final videos = _videos(clock);
    final analyses = _analyses(videos);

    return SwimmerData(
      raceLogs: raceLogs,
      goals: goals,
      meetResults: meetResults,
      profile: profile,
      videos: videos,
      videoAnalyses: analyses,
      usaStandards: motivationalStandards.flatStandards,
      schedules: schedules,
      motivationalStandards: motivationalStandards,
    );
  }

  static SwimmerProfile _profile() {
    return SwimmerProfile(
      id: 9001,
      swimmerName: swimmerName,
      firstName: 'Aspyn',
      lastName: 'Briez',
      preferredName: 'Aspyn Briez',
      birthday: DateTime(2011, 3, 15),
      graduationYear: 2029,
      team: 'COA',
      coachName: 'Gunner Lehr',
      primaryStroke: 'Butterfly',
      secondaryStroke: 'Freestyle',
      favoriteEvent: '100 Butterfly',
      usaSwimmingId: 'DEMO-ASPYN-BRIEZ',
      school: 'Dublin Coffman High School',
      athleteNotes: SwimmerProfile.composeAthleteNotes(
        gender: 'Female',
        height: '5\'7"',
        weight: '128 lb',
        dominantHand: 'Right',
        trainingGroup: 'Senior Gold',
        gpa: '3.85',
        satScore: '1320',
        actScore: '29',
        intendedMajor: 'Exercise science / biology',
        recruitingStatus: 'Open — contacting D1/D2 programs Fall 2026',
        coachEmail: 'coach.lehr@coa-swim.example',
        coachPhone: '(614) 555-0142',
        athleteEmail: 'aspyn.briez@demo.swimiqapp.com',
        athletePhone: '(614) 555-0198',
        athleteWebsite: 'https://swimiqapp.com',
        otherInterests: 'Student council, photography, volunteer swim lessons',
        academicHonors: 'Honor roll · National Honor Society nominee',
        athleticHonors: 'Sectionals finalist · Team fly specialist',
        collegeInterests: 'Ohio, Midwest D1/D2, strong academics + swim',
        leadershipService: 'Volunteer learn-to-swim instructor · team mentor',
        notes:
            'Showcase athlete profile for coach demos. Aspyn logs meets, '
            'uploads race video, tracks cuts, and keeps her recruiting '
            'passport current — this is what consistent SwimIQ use looks like.\n'
            'IMX Score: 1950\n'
            'IMR Score: 1420\n'
            'Swimio: https://myswimio.com/swimmerspage.php?swimmerid=demo-aspyn',
      ),
    );
  }

  static double _t(String time) => SwimTime.toSeconds(time);

  static List<MeetResult> _meetResults() {
    final name = swimmerName;
    return [
      // ── Winter Championships SCY ──────────────────────────────────────
      MeetResult(
        id: 9101,
        swimmerName: name,
        meetName: '2026 COA Winter Championships',
        event: '50 Freestyle',
        swimTime: _t('28.90'),
        course: 'SCY',
        meetDate: DateTime(2026, 1, 18),
        notes: 'Out in 12.4 — strong finish.',
      ),
      MeetResult(
        id: 9102,
        swimmerName: name,
        meetName: '2026 COA Winter Championships',
        event: '100 Freestyle',
        swimTime: _t('1:02.80'),
        course: 'SCY',
        meetDate: DateTime(2026, 1, 18),
      ),
      MeetResult(
        id: 9103,
        swimmerName: name,
        meetName: '2026 COA Winter Championships',
        event: '50 Butterfly',
        swimTime: _t('33.20'),
        course: 'SCY',
        meetDate: DateTime(2026, 1, 19),
        notes: 'Best start of the season.',
      ),
      MeetResult(
        id: 9104,
        swimmerName: name,
        meetName: '2026 COA Winter Championships',
        event: '100 Butterfly',
        swimTime: _t('1:14.50'),
        course: 'SCY',
        meetDate: DateTime(2026, 1, 19),
      ),
      MeetResult(
        id: 9105,
        swimmerName: name,
        meetName: '2026 COA Winter Championships',
        event: '200 IM',
        swimTime: _t('2:35.20'),
        course: 'SCY',
        meetDate: DateTime(2026, 1, 19),
      ),
      // ── Sectionals SCY ────────────────────────────────────────────────
      MeetResult(
        id: 9201,
        swimmerName: name,
        meetName: '2026 OHIO Speedo Sectionals',
        event: '50 Butterfly',
        swimTime: _t('32.40'),
        course: 'SCY',
        meetDate: DateTime(2026, 3, 14),
        notes: 'Season PB — building toward letter cuts.',
      ),
      MeetResult(
        id: 9202,
        swimmerName: name,
        meetName: '2026 OHIO Speedo Sectionals',
        event: '100 Butterfly',
        swimTime: _t('1:12.00'),
        course: 'SCY',
        meetDate: DateTime(2026, 3, 15),
        notes: 'Season PB — best race of the year.',
      ),
      MeetResult(
        id: 9203,
        swimmerName: name,
        meetName: '2026 OHIO Speedo Sectionals',
        event: '200 Butterfly',
        swimTime: _t('2:48.50'),
        course: 'SCY',
        meetDate: DateTime(2026, 3, 15),
      ),
      MeetResult(
        id: 9204,
        swimmerName: name,
        meetName: '2026 OHIO Speedo Sectionals',
        event: '100 Freestyle',
        swimTime: _t('1:01.90'),
        course: 'SCY',
        meetDate: DateTime(2026, 3, 14),
      ),
      MeetResult(
        id: 9205,
        swimmerName: name,
        meetName: '2026 OHIO Speedo Sectionals',
        event: '200 Freestyle',
        swimTime: _t('2:18.40'),
        course: 'SCY',
        meetDate: DateTime(2026, 3, 16),
      ),
      MeetResult(
        id: 9206,
        swimmerName: name,
        meetName: '2026 OHIO Speedo Sectionals',
        event: '100 Backstroke',
        swimTime: _t('1:11.80'),
        course: 'SCY',
        meetDate: DateTime(2026, 3, 16),
      ),
      MeetResult(
        id: 9207,
        swimmerName: name,
        meetName: '2026 OHIO Speedo Sectionals',
        event: '200 IM',
        swimTime: _t('2:32.10'),
        course: 'SCY',
        meetDate: DateTime(2026, 3, 16),
      ),
      // ── Denison LCM invite ─────────────────────────────────────────────
      MeetResult(
        id: 9301,
        swimmerName: name,
        meetName: '2026 Denison Summer Invite',
        event: '50 Butterfly',
        swimTime: _t('36.80'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 7),
        notes: 'First long-course fly of summer.',
      ),
      MeetResult(
        id: 9302,
        swimmerName: name,
        meetName: '2026 Denison Summer Invite',
        event: '100 Butterfly',
        swimTime: _t('1:24.20'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 7),
      ),
      MeetResult(
        id: 9303,
        swimmerName: name,
        meetName: '2026 Denison Summer Invite',
        event: '200 Butterfly',
        swimTime: _t('3:12.50'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 8),
      ),
      MeetResult(
        id: 9304,
        swimmerName: name,
        meetName: '2026 Denison Summer Invite',
        event: '50 Freestyle',
        swimTime: _t('33.40'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 8),
      ),
      MeetResult(
        id: 9305,
        swimmerName: name,
        meetName: '2026 Denison Summer Invite',
        event: '100 Freestyle',
        swimTime: _t('1:12.60'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 8),
      ),
      MeetResult(
        id: 9306,
        swimmerName: name,
        meetName: '2026 Denison Summer Invite',
        event: '400 Freestyle',
        swimTime: _t('5:28.00'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 7),
      ),
      // ── OSU Summer Invite LCM ──────────────────────────────────────────
      MeetResult(
        id: 9401,
        swimmerName: name,
        meetName: '2026 OSU Summer Invite',
        event: '50 Butterfly',
        swimTime: _t('36.10'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 28),
        notes: 'LCM PB.',
      ),
      MeetResult(
        id: 9402,
        swimmerName: name,
        meetName: '2026 OSU Summer Invite',
        event: '100 Butterfly',
        swimTime: _t('1:22.40'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 28),
        notes: 'LCM PB — race video analyzed in Video Lab.',
      ),
      MeetResult(
        id: 9403,
        swimmerName: name,
        meetName: '2026 OSU Summer Invite',
        event: '200 Butterfly',
        swimTime: _t('3:07.00'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 29),
        notes: 'LCM PB.',
      ),
      MeetResult(
        id: 9404,
        swimmerName: name,
        meetName: '2026 OSU Summer Invite',
        event: '200 Freestyle',
        swimTime: _t('2:36.50'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 29),
      ),
      MeetResult(
        id: 9405,
        swimmerName: name,
        meetName: '2026 OSU Summer Invite',
        event: '100 Breaststroke',
        swimTime: _t('1:35.20'),
        course: 'LCM',
        meetDate: DateTime(2026, 6, 28),
      ),
    ];
  }

  static List<RaceLog> _raceLogs(DateTime clock) {
    final name = swimmerName;
    final logs = <RaceLog>[
      RaceLog(
        id: 8001,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('1:15.80'),
        date: DateTime(2026, 2, 3),
        notes: 'Race-pace 4x25 fly @ :40',
      ),
      RaceLog(
        id: 8002,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('1:14.60'),
        date: DateTime(2026, 2, 17),
        notes: 'Broken 100 — underwater focus',
      ),
      RaceLog(
        id: 8003,
        swimmer: name,
        event: '50 Butterfly',
        distance: 50,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('33.80'),
        date: DateTime(2026, 2, 24),
        notes: 'Start + breakout timing',
      ),
      RaceLog(
        id: 8004,
        swimmer: name,
        event: '200 Butterfly',
        distance: 200,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('2:52.00'),
        date: DateTime(2026, 3, 3),
        notes: 'Negative split attempt',
      ),
      RaceLog(
        id: 8005,
        swimmer: name,
        event: '100 Freestyle',
        distance: 100,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: _t('1:03.40'),
        date: DateTime(2026, 3, 5),
      ),
      RaceLog(
        id: 8006,
        swimmer: name,
        event: '200 IM',
        distance: 200,
        stroke: 'IM',
        course: 'SCY',
        timeSeconds: _t('2:34.00'),
        date: DateTime(2026, 3, 10),
        notes: 'Breast→free transition drill set',
      ),
      RaceLog(
        id: 8007,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('1:13.20'),
        date: DateTime(2026, 3, 12),
        notes: 'Taper feel — ready for Sectionals',
      ),
      RaceLog(
        id: 8008,
        swimmer: name,
        event: '50 Freestyle',
        distance: 50,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: _t('29.40'),
        date: DateTime(2026, 4, 8),
      ),
      RaceLog(
        id: 8009,
        swimmer: name,
        event: '100 Backstroke',
        distance: 100,
        stroke: 'Backstroke',
        course: 'SCY',
        timeSeconds: _t('1:12.90'),
        date: DateTime(2026, 4, 15),
      ),
      RaceLog(
        id: 8010,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: _t('1:25.00'),
        date: DateTime(2026, 5, 20),
        notes: 'First LCM fly set of summer',
      ),
      RaceLog(
        id: 8011,
        swimmer: name,
        event: '200 Butterfly',
        distance: 200,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: _t('3:14.00'),
        date: DateTime(2026, 5, 27),
      ),
      RaceLog(
        id: 8012,
        swimmer: name,
        event: '50 Butterfly',
        distance: 50,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: _t('37.20'),
        date: DateTime(2026, 6, 3),
        notes: 'Denison prep — start reaction 0.68',
      ),
      RaceLog(
        id: 8013,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: _t('1:23.50'),
        date: DateTime(2026, 6, 17),
      ),
      RaceLog(
        id: 8014,
        swimmer: name,
        event: '400 Freestyle',
        distance: 400,
        stroke: 'Freestyle',
        course: 'LCM',
        timeSeconds: _t('5:30.00'),
        date: DateTime(2026, 6, 18),
      ),
      RaceLog(
        id: 8015,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: _t('1:22.90'),
        date: DateTime(2026, 6, 24),
        notes: 'OSU Invite taper — underwater + breathing pattern',
      ),
      RaceLog(
        id: 8016,
        swimmer: name,
        event: '200 Butterfly',
        distance: 200,
        stroke: 'Butterfly',
        course: 'LCM',
        timeSeconds: _t('3:09.50'),
        date: DateTime(2026, 6, 25),
      ),
      RaceLog(
        id: 8017,
        swimmer: name,
        event: '50 Butterfly',
        distance: 50,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('32.90'),
        date: DateTime(2026, 7, 8),
        notes: 'Short-course speed maintenance',
      ),
      RaceLog(
        id: 8018,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('1:12.40'),
        date: DateTime(2026, 7, 15),
      ),
      RaceLog(
        id: 8019,
        swimmer: name,
        event: '200 IM',
        distance: 200,
        stroke: 'IM',
        course: 'SCY',
        timeSeconds: _t('2:33.00'),
        date: DateTime(2026, 7, 17),
      ),
      RaceLog(
        id: 8020,
        swimmer: name,
        event: '100 Freestyle',
        distance: 100,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: _t('1:02.20'),
        date: DateTime(2026, 7, 22),
        notes: 'Aerobic threshold free',
      ),
    ];

    // Keep a couple of recent sessions relative to "today" so Dashboard /
    // Dryland "this week" load looks active whenever the demo is opened.
    final weekStart = clock.subtract(Duration(days: clock.weekday - 1));
    logs.addAll([
      RaceLog(
        id: 8021,
        swimmer: name,
        event: '100 Butterfly',
        distance: 100,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('1:12.10'),
        date: weekStart,
        notes: 'Mid-week race-pace fly',
      ),
      RaceLog(
        id: 8022,
        swimmer: name,
        event: '50 Butterfly',
        distance: 50,
        stroke: 'Butterfly',
        course: 'SCY',
        timeSeconds: _t('32.70'),
        date: weekStart.add(const Duration(days: 2)),
        notes: 'Starts + 15m underwater',
      ),
      RaceLog(
        id: 8023,
        swimmer: name,
        event: '200 Freestyle',
        distance: 200,
        stroke: 'Freestyle',
        course: 'SCY',
        timeSeconds: _t('2:19.00'),
        date: weekStart.add(const Duration(days: 3)),
      ),
    ]);
    return logs;
  }

  static List<SwimGoal> _goals(DateTime clock) {
    final name = swimmerName;
    final fall = DateTime(clock.year, 11, 15);
    final spring = DateTime(clock.year + 1, 3, 20);
    return [
      SwimGoal(
        id: 7001,
        swimmerName: name,
        event: '100 Butterfly',
        goalTime: _t('1:08.00'),
        course: 'SCY',
        targetDate: fall,
        currentTime: _t('1:12.00'),
      ),
      SwimGoal(
        id: 7002,
        swimmerName: name,
        event: '50 Butterfly',
        goalTime: _t('31.50'),
        course: 'SCY',
        targetDate: fall,
        currentTime: _t('32.40'),
      ),
      SwimGoal(
        id: 7003,
        swimmerName: name,
        event: '200 Butterfly',
        goalTime: _t('2:40.00'),
        course: 'SCY',
        targetDate: spring,
        currentTime: _t('2:48.50'),
      ),
      SwimGoal(
        id: 7004,
        swimmerName: name,
        event: '100 Butterfly',
        goalTime: _t('1:18.00'),
        course: 'LCM',
        targetDate: DateTime(clock.year, 8, 1),
        currentTime: _t('1:22.40'),
      ),
      SwimGoal(
        id: 7005,
        swimmerName: name,
        event: '200 Butterfly',
        goalTime: _t('2:59.00'),
        course: 'LCM',
        targetDate: DateTime(clock.year, 8, 1),
        currentTime: _t('3:07.00'),
      ),
      SwimGoal(
        id: 7006,
        swimmerName: name,
        event: '200 IM',
        goalTime: _t('2:26.00'),
        course: 'SCY',
        targetDate: spring,
        currentTime: _t('2:32.10'),
      ),
      SwimGoal(
        id: 7007,
        swimmerName: name,
        event: '100 Freestyle',
        goalTime: _t('59.50'),
        course: 'SCY',
        targetDate: fall,
        currentTime: _t('1:01.90'),
      ),
    ];
  }

  static List<SwimScheduleEntry> _schedules(DateTime clock) {
    final name = swimmerName;
    final today = DateTime(clock.year, clock.month, clock.day);
    return [
      SwimScheduleEntry(
        id: 6001,
        swimmerName: name,
        scheduleType: SwimScheduleEntry.typePractice,
        title: 'Senior Gold AM practice',
        scheduleDate: today.add(const Duration(days: 1)),
        startTime: '05:45',
        location: 'COA Natatorium',
        eventsLine: 'Fly specialty · race-pace 100s',
        notes: 'Bring fins + snorkel',
        createdAt: clock.subtract(const Duration(days: 10)),
      ),
      SwimScheduleEntry(
        id: 6002,
        swimmerName: name,
        scheduleType: SwimScheduleEntry.typePractice,
        title: 'Senior Gold PM practice',
        scheduleDate: today.add(const Duration(days: 2)),
        startTime: '15:30',
        location: 'COA Natatorium',
        eventsLine: 'Aerobic free + IM transitions',
        createdAt: clock.subtract(const Duration(days: 10)),
      ),
      SwimScheduleEntry(
        id: 6003,
        swimmerName: name,
        scheduleType: SwimScheduleEntry.typeMeet,
        title: 'Central Ohio Summer Classic',
        scheduleDate: today.add(const Duration(days: 12)),
        startTime: '08:00',
        location: 'Worthington, OH',
        eventsLine: '50 Fly, 100 Fly, 200 Free, 200 IM',
        notes: 'Goal: SCY 100 Fly under 1:10.0',
        createdAt: clock.subtract(const Duration(days: 20)),
      ),
      SwimScheduleEntry(
        id: 6004,
        swimmerName: name,
        scheduleType: SwimScheduleEntry.typeMeet,
        title: '2026 Futures Championship (watchlist)',
        scheduleDate: today.add(const Duration(days: 45)),
        startTime: '09:00',
        location: 'Geneva, OH',
        eventsLine: '100 Fly, 200 Fly',
        notes: 'Cut chase meet — track vs Power Index goals',
        createdAt: clock.subtract(const Duration(days: 5)),
      ),
      SwimScheduleEntry(
        id: 6005,
        swimmerName: name,
        scheduleType: SwimScheduleEntry.typeRace,
        title: 'Time trial — 100 Fly SCY',
        scheduleDate: today.add(const Duration(days: 5)),
        startTime: '16:00',
        location: 'COA Natatorium',
        eventsLine: '100 Butterfly',
        notes: 'Coach Gunner — race video upload after',
        createdAt: clock.subtract(const Duration(days: 2)),
      ),
      SwimScheduleEntry(
        id: 6006,
        swimmerName: name,
        scheduleType: SwimScheduleEntry.typePractice,
        title: 'Dryland + mobility',
        scheduleDate: today.add(const Duration(days: 3)),
        startTime: '06:15',
        location: 'COA Dryland Room',
        eventsLine: 'Core · scapular stability · ankle mobility',
        notes: 'Matches AI Dryland Coach priorities from Video Lab',
        createdAt: clock.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<SwimVideo> _videos(DateTime clock) {
    final name = swimmerName;
    return [
      SwimVideo(
        id: 'a1111111-1111-4111-8111-111111111101',
        swimmer: name,
        storagePath: 'demo/aspyn-briez/osu-100-fly-lcm.mov',
        title: 'OSU Invite 100 Fly LCM',
        stroke: 'Butterfly',
        distance: '100',
        course: 'LCM',
        notes:
            'Reaction ~0.70. Strong breakout. Breathing every other stroke '
            'second 50. Finish long — felt late on the wall.',
        createdAt: DateTime(2026, 6, 28, 18, 30),
      ),
      SwimVideo(
        id: 'a1111111-1111-4111-8111-111111111102',
        swimmer: name,
        storagePath: 'demo/aspyn-briez/denison-50-fly.mov',
        title: 'Denison 50 Fly #2',
        stroke: 'Butterfly',
        distance: '50',
        course: 'LCM',
        notes:
            'Start reaction 0.68. Underwater 12m. Hips a little high mid-pool. '
            'Finish with fingertips first.',
        createdAt: DateTime(2026, 6, 7, 16, 10),
      ),
      SwimVideo(
        id: 'a1111111-1111-4111-8111-111111111103',
        swimmer: name,
        storagePath: 'demo/aspyn-briez/sectionals-100-fly-scy.mov',
        title: 'Sectionals 100 Fly SCY PB',
        stroke: 'Butterfly',
        distance: '100',
        course: 'SCY',
        notes:
            'Best race of the year. Underwaters 1–3 solid. Turn 2 a bit slow. '
            'Held stroke rate through the last 15.',
        createdAt: DateTime(2026, 3, 15, 14, 5),
      ),
      SwimVideo(
        id: 'a1111111-1111-4111-8111-111111111104',
        swimmer: name,
        storagePath: 'demo/aspyn-briez/practice-breakout-drills.mov',
        title: 'Practice — fly breakout drills',
        stroke: 'Butterfly',
        distance: '50',
        course: 'SCY',
        notes:
            'Coach feedback day. Focus: first kick timing and head position '
            'on breakout. 8x15m underwater + breakout.',
        createdAt: DateTime(2026, 5, 12, 17, 0),
      ),
      SwimVideo(
        id: 'a1111111-1111-4111-8111-111111111105',
        swimmer: name,
        storagePath: 'demo/aspyn-briez/200-fly-negative-split.mov',
        title: '200 Fly negative-split attempt',
        stroke: 'Butterfly',
        distance: '200',
        course: 'SCY',
        notes:
            'Even first 100, build second. Breathing pattern 2-2-1 last 50. '
            'Need tighter line on third 50.',
        createdAt: DateTime(2026, 3, 3, 19, 20),
      ),
    ];
  }

  static List<SwimVideoAnalysis> _analyses(List<SwimVideo> videos) {
    return [
      _analysis(
        video: videos[0],
        technique: 86,
        pace: 84,
        overall: 85,
        summary:
            '100 Butterfly LCM — strong underwater openings with room to '
            'sharpen the finish and second-50 breathing rhythm.',
        strengths:
            'Explosive breakout speed; consistent kick amplitude; race plan '
            'held through the third 25.',
        improvements:
            'Late-race body line; finish timing; breathing pattern under fatigue.',
        priorities: const [
          'Hold a longer streamline into the final wall — drive fingertips first',
          'Stabilize breathing every-other pattern on the second 50',
          'Add one extra dolphin kick off walls 2 and 3 when fresh',
        ],
        drills: const [
          '8x15m underwater dolphin + breakout @ :40',
          '6x50 fly breathe every other, odds easy / evens race-pace',
          'Finish ladders: 4x25 build to touch with no breath last 8m',
        ],
        pose: const SwimPoseMetrics(
          engine: SwimPoseMetrics.engineId,
          framesSampled: 120,
          framesWithPose: 108,
          avgBodyLineAngleDeg: 8.5,
          hipDropDegrees: 6.2,
          headLiftScore: 0.72,
          avgElbowAngleDeg: 118,
          estimatedStrokeCycles: 42,
          kickSymmetryScore: 0.88,
          bodyMechanicsPro:
              'Body line stays relatively flat through the first 75 meters.',
          bodyMechanicsCon:
              'Slight hip drop and earlier head lift appear in the final 25.',
          bodyMechanicsSuggestions: [
            'Cue “hips up, chin tucked” on the last 15 meters',
            'Film one underwater side view next practice for kick timing',
          ],
          observations: [
            'Detection rate strong across race footage',
            'Kick symmetry remains high until final 25',
            'Head lift increases under fatigue — matches athlete notes',
          ],
        ),
      ),
      _analysis(
        video: videos[1],
        technique: 88,
        pace: 90,
        overall: 89,
        summary:
            '50 Butterfly LCM — excellent start/breakout package; mid-pool '
            'hip position is the next free speed.',
        strengths:
            'Reaction and underwater distance; aggressive first stroke cycle; '
            'committed finish.',
        improvements: 'Mid-race hip height; early vertical forearm setup.',
        priorities: const [
          'Keep hips closer to the surface mid-pool',
          'Set an earlier catch without rushing the recovery',
          'Replicate the same breakout distance in practice starts',
        ],
        drills: const [
          '12x start + 15m underwater (time to 15m)',
          'Single-arm fly with focus on early catch',
          'Hip-buoy 25s fly kick on stomach',
        ],
        pose: const SwimPoseMetrics(
          engine: SwimPoseMetrics.engineId,
          framesSampled: 60,
          framesWithPose: 55,
          avgBodyLineAngleDeg: 7.1,
          hipDropDegrees: 4.8,
          headLiftScore: 0.64,
          avgElbowAngleDeg: 122,
          estimatedStrokeCycles: 18,
          kickSymmetryScore: 0.91,
          observations: [
            'Clean start posture on the block',
            'Breakout timing aligns with strong first stroke',
          ],
        ),
      ),
      _analysis(
        video: videos[2],
        technique: 91,
        pace: 92,
        overall: 92,
        summary:
            'Sectionals 100 Fly SCY PB — championship-caliber race execution. '
            'Small turn-speed gains still available.',
        strengths:
            'Stroke rate under pressure; underwater 1–3; composure last 15 yards.',
        improvements: 'Turn 2 foot speed; slightly longer glide before kick 1.',
        priorities: const [
          'Sharpen turn 2 — faster feet to the wall, quicker pullout',
          'Keep the same stroke count as the PB race in practice broken 100s',
          'Film turns weekly; compare wall contact angle',
        ],
        drills: const [
          '16x25 fly @ race stroke count',
          'Turn circuit: 8x approach + flip + 3 kicks',
          'Broken 100s (50/50) holding PB stroke rate',
        ],
      ),
      _analysis(
        video: videos[3],
        technique: 82,
        pace: 80,
        overall: 81,
        summary:
            'Practice breakout session — clear progress on first-kick timing; '
            'head position still variable.',
        strengths: 'Coachable adjustments between reps; consistent effort.',
        improvements: 'Head/chin position on breakout; first kick timing lag.',
        priorities: const [
          'Chin slightly tucked until first stroke clears the water',
          'Time first dolphin kick with hand entry, not after',
          'Log 10 quality breakouts before the next meet video',
        ],
        drills: const [
          '10x15m underwater + breakout, video every 3rd rep',
          'Snorkel fly kick for head stillness',
          'Tempo trainer breakouts at race rate',
        ],
      ),
      _analysis(
        video: videos[4],
        technique: 84,
        pace: 83,
        overall: 84,
        summary:
            '200 Fly negative-split attempt — pacing discipline is improving; '
            'third-50 body line needs attention.',
        strengths: 'Controlled first 100; smart breathing pattern late.',
        improvements: 'Third-50 alignment; sustaining kick amplitude.',
        priorities: const [
          'Protect body line on the third 50 — shorter, sharper kicks',
          'Use 2-2-1 breathing only after stroke rhythm is locked',
          'Practice 3x150 fly descending to simulate late-race fatigue',
        ],
        drills: const [
          '3x150 fly @ negative split, easy 100 between',
          'Kickboard vertical kick 4x30s for late-race kick power',
          '200 IM swim focusing breast→free transition carryover',
        ],
      ),
    ];
  }

  static SwimVideoAnalysis _analysis({
    required SwimVideo video,
    required int technique,
    required int pace,
    required int overall,
    required String summary,
    required String strengths,
    required String improvements,
    required List<String> priorities,
    required List<String> drills,
    SwimPoseMetrics? pose,
  }) {
    final eventLabel = video.eventLabel;
    final sections = <String, String>{
      'Quick Summary': summary,
      'What the video suggests': priorities.map((p) => '• $p').join('\n'),
      'Top 3 priorities for the next practice':
          priorities.take(3).map((p) => '• $p').join('\n'),
      'Specific drills': drills.map((d) => '• $d').join('\n'),
      'Estimated time savings':
          'Cleaning the top priorities could free ~0.3–0.8s in $eventLabel '
          'over the next 4–6 weeks with consistent practice logging.',
      'Coach notes for next race':
          'Aspyn should warm up with two race-pace breakouts, then swim the '
          'plan already logged in Goals for $eventLabel. Upload the race video '
          'the same day so SwimDNA and Dryland stay synced.',
    };

    return SwimVideoAnalysis(
      id: 'b${video.id!.substring(1)}',
      swimVideoId: video.id,
      swimmer: swimmerName,
      summary: '$eventLabel\n\n$summary',
      strengths: strengths,
      improvements: improvements,
      techniqueScore: technique,
      paceScore: pace,
      overallScore: overall,
      createdAt: video.createdAt,
      analysisJson: {
        'event': eventLabel,
        'stroke': video.stroke,
        'distance': video.distance,
        'course': video.course,
        'user_notes': video.notes,
        'disclaimer':
            'Showcase demo analysis for coach walkthroughs — sample feedback '
            'illustrating SwimIQ AI coaching output.',
        'sections': sections,
        'top_3_priorities': priorities.take(3).toList(),
        'recommended_drills': drills,
        'engine': 'swimiq-v2-gemini',
        if (pose != null) 'pose_metrics': pose.toJson(),
      },
    );
  }
}
