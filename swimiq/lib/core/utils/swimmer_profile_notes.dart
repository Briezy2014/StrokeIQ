import '../../data/models/swimmer_profile.dart';

/// Merges structured athlete note fields so partial saves keep social/peer data.
abstract final class SwimmerProfileNotes {
  static String merge({
    SwimmerProfile? existing,
    String? gender,
    String? height,
    String? weight,
    String? dominantHand,
    String? trainingGroup,
    String? profilePhotoUrl,
    String? sleepHours,
    String? sorenessLevel,
    String? illnessNotes,
    List<String>? attendingMeetIds,
    String? instagram,
    String? tiktok,
    String? facebook,
    String? website,
    bool? publicPassport,
    List<String>? interestSports,
    List<String>? interestAcademics,
    List<String>? interestPassions,
    String? beyondBio,
    String? notes,
  }) {
    return SwimmerProfile.composeAthleteNotes(
      gender: gender ?? existing?.gender,
      height: height ?? existing?.height,
      weight: weight ?? existing?.weight,
      dominantHand: dominantHand ?? existing?.dominantHand,
      trainingGroup: trainingGroup ?? existing?.trainingGroup,
      profilePhotoUrl: profilePhotoUrl ?? existing?.profilePhotoUrl,
      sleepHours: sleepHours ?? existing?.sleepHours,
      sorenessLevel: sorenessLevel ?? existing?.sorenessLevel,
      illnessNotes: illnessNotes ?? existing?.illnessNotes,
      attendingMeetIds: attendingMeetIds ?? existing?.attendingMeetIds,
      instagram: instagram ?? existing?.instagram,
      tiktok: tiktok ?? existing?.tiktok,
      facebook: facebook ?? existing?.facebook,
      website: website ?? existing?.personalWebsite,
      publicPassport: publicPassport ?? existing?.publicPassportEnabled,
      interestSports: interestSports ?? existing?.interestSports,
      interestAcademics: interestAcademics ?? existing?.interestAcademics,
      interestPassions: interestPassions ?? existing?.interestPassions,
      beyondBio: beyondBio ?? existing?.beyondBio,
      notes: notes ?? existing?.notesBody,
    );
  }
}
