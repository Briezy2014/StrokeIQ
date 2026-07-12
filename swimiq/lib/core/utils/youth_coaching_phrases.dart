/// Plain-language swim coaching copy for youth swimmers and parents.
abstract final class YouthCoachingPhrases {
  static const finishStrongPro =
      'Strong finish — you completed your last stroke before touching the wall: '
      'you reached forward, kept pushing through the water, and touched with a long arm '
      'instead of shortening up or gliding in.';

  static const finishFocusPriority =
      'Finish your final stroke completely before touching the wall. '
      'Reach all the way forward, keep driving through the water, and touch with a '
      'fully extended arm instead of shortening or gliding into the wall.';

  static const finishWallReminder =
      'Last few meters: do not coast — take one strong stroke and reach to the wall '
      'with a long arm before you touch.';

  static const breakoutAwarenessPro =
      'Good breakout focus — you know when to take your first stroke after your '
      'underwater. That race awareness helps you swim smarter.';

  static const solidBreakoutPro =
      'Solid underwater work — you stayed under long enough and carried your speed '
      'when you came up for your first stroke.';

  static const holdStreamlinePriority =
      'Stay in your tight streamline a little longer (arms squeezed behind your '
      'ears) before you take your first stroke.';

  static const startStreamlineCue =
      'On the beep: push off hard and go into your streamline first, '
      'then build speed on your first stroke.';

  static const practicedStartCue =
      'On the beep: use the same start you practiced — streamline first, '
      'then build speed.';

  static const fastStartStreamlineCue =
      'On the beep: push off hard and go into your streamline '
      '(arms tight behind your ears) before your first stroke.';

  static const avoidOverGlidingBetweenStrokes =
      'Add rhythm between strokes — do not pause too long with your arms stretched out.';

  static const completeLastStrokeReach =
      'A complete last stroke with a long reach to the wall';

  static const strongerFinishReach =
      'One more strong stroke and a long reach to the wall before you touch';

  static const tighterStreamlineOffWalls =
      'Push off into your streamline (arms tight behind your ears) '
      'off the start and every turn';

  static const longerUnderwaterBeforeFirstStroke =
      'Stay underwater a little longer before you come up for your first stroke';

  static const reviewedStartStreamline =
      'You reviewed the start on video — keep the same hard push into your '
      'streamline (arms tight behind your ears).';

  static const blockReadyCue =
      'Behind the blocks: eyes slightly down or out, loose shoulders, ready to go.';

  static const takeYourMarksCue =
      'On "take your marks": tighten your body — stay coiled and still.';

  static const explodeOnBeepCue =
      'On the beep: explode off the blocks into your streamline '
      '(arms tight behind your ears).';

  static const startSharpeningCon =
      'Work on your start — eyes slightly down or out before the call, '
      'tighten on "take your marks," then explode on the beep into your '
      'streamline underwater.';

  static const startSharpeningNotesHint =
      'You noted your start — log a reaction time on your next upload so we can '
      'track block speed.';

  static const tightenBlockSetupPriority =
      'Block routine: eyes slightly down or out, tighten on "take your marks," '
      'explode on the beep into your streamline.';

  /// Race-day strength cue when upload notes are empty (notes-only fallback).
  static String eventGoingWell(String eventLabel, String stroke, bool isSprint) {
    return switch (stroke) {
      'Butterfly' => isSprint
          ? 'on $eventLabel, fly sprinters build speed with a fast start and steady rhythm on the second 25.'
          : 'on $eventLabel, strong fly means hips up, a clean catch, and breathing without lifting your head.',
      'Freestyle' => isSprint
          ? 'on $eventLabel, sprint free rewards a sharp start, tight streamline, and tempo that does not fade.'
          : 'on $eventLabel, check body line, breathing pattern, and whether tempo holds on each length.',
      'Backstroke' => 'on $eventLabel, keep a straight body line, steady kick, and strong push-offs.',
      'Breaststroke' => 'on $eventLabel, pull-out, glide timing, and a quick kick drive each length.',
      'IM' => 'on $eventLabel, transitions and carrying speed off each wall matter as much as each stroke.',
      _ => 'on $eventLabel, race footage helps you spot start, turns, and finish before the next meet.',
    };
  }

  static String strokeTechniqueWorkOn(String stroke) {
    return switch (stroke) {
      'Butterfly' =>
          'hips up, head down on breaths, and a steady kick off the start and walls.',
      'Freestyle' =>
          'hips near the surface, head down, and a high-elbow catch on every pull.',
      'Backstroke' =>
          'hips up, steady kick, and a flat body line from shoulders to ankles.',
      'Breaststroke' =>
          'a long glide, quick kick, and driving your hips forward on each pull.',
      'IM' => 'clean turns, tight streamlines, and carrying speed stroke to stroke.',
      _ => 'flat body line, steady kick, and a connected pull.',
    };
  }

  static String raceReadinessWorkOn({required bool isSprint}) => isSprint
      ? 'eyes slightly down before the call, tighten on "take your marks," explode on the beep into streamline.'
      : 'strong push-offs, steady middle tempo, and a complete last stroke at the wall.';

  static const paceRhythmWorkOn =
      'hold the same stroke rhythm from the start through the middle and finish.';

  static String finishStrongProForEvent(String event) =>
      'Strong finish on $event — you completed your last stroke before touching the wall: '
      'you reached forward, kept pushing through the water, and touched with a long arm '
      'instead of shortening up or gliding in.';
}
