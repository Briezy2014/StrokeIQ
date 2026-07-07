import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_plan.dart';

class SubscriptionState {
  const SubscriptionState({
    required this.tier,
    required this.billingCycle,
    required this.trialEndsAt,
    required this.coachTrialEndsAt,
    required this.coachTrialStartedAt,
    required this.coachAiAnalysesUsed,
    required this.hasUsedTrial,
  });

  final SubscriptionTier tier;
  final BillingCycle billingCycle;
  final DateTime? trialEndsAt;
  final DateTime? coachTrialEndsAt;
  final DateTime? coachTrialStartedAt;
  final int coachAiAnalysesUsed;
  final bool hasUsedTrial;

  bool get isTrialActive =>
      trialEndsAt != null && DateTime.now().isBefore(trialEndsAt!);

  bool get isCoachTrialActive =>
      coachTrialEndsAt != null &&
      DateTime.now().isBefore(coachTrialEndsAt!);

  bool get hasCoachElitePeek {
    if (!isCoachTrialActive || coachTrialStartedAt == null) return false;
    final peekEnds = coachTrialStartedAt!.add(
      Duration(days: SubscriptionCatalog.coachElitePeekDays),
    );
    final withinWindow = DateTime.now().isBefore(peekEnds);
    final underLimit =
        coachAiAnalysesUsed < SubscriptionCatalog.coachEliteAnalysisLimit;
    return withinWindow && underLimit;
  }

  int get coachTrialDaysRemaining {
    if (!isCoachTrialActive || coachTrialEndsAt == null) return 0;
    return coachTrialEndsAt!.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  SubscriptionTier get effectiveTier {
    if (isCoachTrialActive) {
      return hasCoachElitePeek ? SubscriptionTier.elite : SubscriptionTier.pro;
    }
    if (isTrialActive) return SubscriptionTier.elite;
    return tier;
  }

  String get statusLabel {
    if (isCoachTrialActive) {
      return hasCoachElitePeek
          ? 'Coach preview · Elite AI sneak peek'
          : 'Coach preview · Pro';
    }
    if (isTrialActive) return 'Elite trial active';
    return SubscriptionCatalog.planFor(tier).name;
  }

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    BillingCycle? billingCycle,
    DateTime? trialEndsAt,
    DateTime? coachTrialEndsAt,
    DateTime? coachTrialStartedAt,
    int? coachAiAnalysesUsed,
    bool? hasUsedTrial,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      billingCycle: billingCycle ?? this.billingCycle,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      coachTrialEndsAt: coachTrialEndsAt ?? this.coachTrialEndsAt,
      coachTrialStartedAt: coachTrialStartedAt ?? this.coachTrialStartedAt,
      coachAiAnalysesUsed: coachAiAnalysesUsed ?? this.coachAiAnalysesUsed,
      hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
    );
  }
}

class SubscriptionService {
  static const _tierKey = 'subscription_tier';
  static const _cycleKey = 'subscription_billing_cycle';
  static const _trialEndsKey = 'subscription_trial_ends';
  static const _coachTrialEndsKey = 'subscription_coach_trial_ends';
  static const _coachTrialStartedKey = 'subscription_coach_trial_started';
  static const _coachAiAnalysesKey = 'subscription_coach_ai_analyses_used';
  static const _hasUsedTrialKey = 'subscription_has_used_trial';

  Future<SubscriptionState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tierName = prefs.getString(_tierKey);
    final cycleName = prefs.getString(_cycleKey);
    final trialEnds = _readDate(prefs.getString(_trialEndsKey));
    final coachTrialEnds = _readDate(prefs.getString(_coachTrialEndsKey));
    final coachTrialStarted = _readDate(prefs.getString(_coachTrialStartedKey));
    final coachAiAnalysesUsed = prefs.getInt(_coachAiAnalysesKey) ?? 0;
    final hasUsedTrial = prefs.getBool(_hasUsedTrialKey) ?? false;

    return SubscriptionState(
      tier: _parseTier(tierName),
      billingCycle: cycleName == BillingCycle.annual.name
          ? BillingCycle.annual
          : BillingCycle.monthly,
      trialEndsAt: trialEnds,
      coachTrialEndsAt: coachTrialEnds,
      coachTrialStartedAt: coachTrialStarted,
      coachAiAnalysesUsed: coachAiAnalysesUsed,
      hasUsedTrial: hasUsedTrial,
    );
  }

  Future<SubscriptionState> startTrialIfEligible(SubscriptionState current) async {
    if (current.hasUsedTrial && !current.isTrialActive) return current;

    final endsAt = DateTime.now().add(
      Duration(days: SubscriptionCatalog.trialDays),
    );
    final updated = current.copyWith(
      trialEndsAt: endsAt,
      hasUsedTrial: true,
    );
    await _save(updated);
    return updated;
  }

  Future<SubscriptionState> redeemCoachCode(
    SubscriptionState current,
    String code,
  ) async {
    if (!SubscriptionCatalog.isCoachAccessCode(code)) {
      throw FormatException('Invalid coach access code.');
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      coachTrialStartedAt: now,
      coachTrialEndsAt: now.add(
        Duration(days: SubscriptionCatalog.coachTrialDays),
      ),
      coachAiAnalysesUsed: 0,
    );
    await _save(updated);
    return updated;
  }

  Future<SubscriptionState> recordCoachAiAnalysis(SubscriptionState current) async {
    if (!current.isCoachTrialActive || !current.hasCoachElitePeek) {
      return current;
    }
    final updated = current.copyWith(
      coachAiAnalysesUsed: current.coachAiAnalysesUsed + 1,
    );
    await _save(updated);
    return updated;
  }

  Future<SubscriptionState> selectPlan({
    required SubscriptionState current,
    required SubscriptionTier tier,
    required BillingCycle billingCycle,
  }) async {
    final updated = current.copyWith(
      tier: tier,
      billingCycle: billingCycle,
    );
    await _save(updated);
    return updated;
  }

  Future<void> _save(SubscriptionState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tierKey, state.tier.name);
    await prefs.setString(_cycleKey, state.billingCycle.name);
    await prefs.setBool(_hasUsedTrialKey, state.hasUsedTrial);
    await _writeDate(prefs, _trialEndsKey, state.trialEndsAt);
    await _writeDate(prefs, _coachTrialEndsKey, state.coachTrialEndsAt);
    await _writeDate(prefs, _coachTrialStartedKey, state.coachTrialStartedAt);
    await prefs.setInt(_coachAiAnalysesKey, state.coachAiAnalysesUsed);
  }

  SubscriptionTier _parseTier(String? value) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.name == value,
      orElse: () => SubscriptionTier.trial,
    );
  }

  DateTime? _readDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _writeDate(
    SharedPreferences prefs,
    String key,
    DateTime? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value.toIso8601String());
  }
}
