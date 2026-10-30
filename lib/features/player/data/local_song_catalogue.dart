
import '../models/song.dart';

class LocalSongCatalogue {
  LocalSongCatalogue._();

  static const List<Song> songs = [
    Song(
      id: 'local_001',
      title: 'Closer x Salaam E Ishq Mashup',
      artist: 'Anna & Rohan',
      album: 'Mashup Collection',
      artwork: '',
      audioSource:
          'assets/audio/Closer x Salaam E Ishq Mashup (Full Version)X OyeEditorrAnna & @ROHANIN.mp3',
      duration: Duration.zero,
      providerId: 'local',
    ),

    Song(
      id: 'local_002',
      title: 'Om Shanti Om x Dekha Tainu Pehli Baar',
      artist: 'Shroid Music & Oyeeditoranna',
      album: 'Nostalgic Mashup',
      artwork: '',
      audioSource:
          'assets/audio/Om Shanti Om X Dekha Tainu Pehli Baar Nostalgic Mashup ( Shroid Music & Oyeeditoranna ).mp3',
      duration: Duration.zero,
      providerId: 'local',
    ),

    Song(
      id: 'local_003',
      title: 'Pink Blue x Saude Baazi',
      artist: 'Gravero x SushyYohanMusic',
      album: 'Mega Mashup',
      artwork: '',
      audioSource:
          'assets/audio/Pink Blue x Saude Baazi - Mega Mashup (Gravero x @SushyYohanMusic) @GULLYGANG.mp3',
      duration: Duration.zero,
      providerId: 'local',
    ),
  ];
}
