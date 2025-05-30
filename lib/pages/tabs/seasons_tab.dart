import 'package:flutter/material.dart';
import 'package:simpsons_park/models/season_model.dart';
import 'package:simpsons_park/models/episode_model.dart';
import 'package:simpsons_park/models/character_model.dart';

class SeasonsTab extends StatefulWidget {
  const SeasonsTab({super.key});

  @override
  State<SeasonsTab> createState() => _SeasonsTabState();
}

class _SeasonsTabState extends State<SeasonsTab> {
  // Sample data - replace with your actual data fetching logic
  final List<Season> _seasons = [
    Season(
      seasonNumber: 1,
      episodes: [
        Episode(
          seasonNumber: 1,
          episodeNumber: 1,
          title: 'Episode 1',
          synopsis: 'Synopsis of Episode 1',
          code: 'EP1',
          duration: '00:30',
          releaseDate: DateTime.now(),
          characters: [
            Character(
              firstName: 'Homer',
              lastName: 'Simpson',
              pseudo: 'Homer',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Homer',
            ),
            Character(
              firstName: 'Marge',
              lastName: 'Simpson',
              pseudo: 'Marge',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Marge',
            ),
          ],
          imageUrl: 'https://placehold.co/200',
        ),
        Episode(
          seasonNumber: 1,
          episodeNumber: 2,
          title: 'Episode 2',
          synopsis: 'Synopsis of Episode 2',
          code: 'EP2',
          duration: '00:30',
          releaseDate: DateTime.now(),
          characters: [
            Character(
              firstName: 'Homer',
              lastName: 'Simpson',
              pseudo: 'Homer',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Homer',
            ),
            Character(
              firstName: 'Marge',
              lastName: 'Simpson',
              pseudo: 'Marge',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Marge',
            ),
          ],
          imageUrl: 'https://placehold.co/200',
        ),
      ],
    ),
    Season(
      seasonNumber: 2,
      episodes: [
        Episode(
          seasonNumber: 2,
          episodeNumber: 1,
          title: 'Episode 1',
          synopsis: 'Synopsis of Episode 1',
          code: 'EP1',
          duration: '00:30',
          releaseDate: DateTime.now(),
          characters: [
            Character(
              firstName: 'Homer',
              lastName: 'Simpson',
              pseudo: 'Homer',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Homer',
            ),
            Character(
              firstName: 'Marge',
              lastName: 'Simpson',
              pseudo: 'Marge',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Marge',
            ),
          ],
          imageUrl: 'https://placehold.co/200',
        ),
        Episode(
          seasonNumber: 2,
          episodeNumber: 2,
          title: 'Episode 2',
          synopsis: 'Synopsis of Episode 2',
          code: 'EP2',
          duration: '00:30',
          releaseDate: DateTime.now(),
          characters: [
            Character(
              firstName: 'Homer',
              lastName: 'Simpson',
              pseudo: 'Homer',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Homer',
            ),
            Character(
              firstName: 'Marge',
              lastName: 'Simpson',
              pseudo: 'Marge',
              imageUrl: 'https://placehold.co/200',
              history: 'History of Marge',
            ),
          ],
          imageUrl: 'https://placehold.co/200',
        ),
      ],
    ),
    // Add more seasons
  ];

  Season? _selectedSeason;

  void _onSeasonTapped(Season season) {
    setState(() {
      _selectedSeason = season;
    });
    // You could navigate to a new screen here to show episodes
    // For simplicity, we'll show them in this same widget for now.
    // Navigator.push(context, MaterialPageRoute(builder: (context) => EpisodesScreen(season: season)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // List of Seasons
        Expanded(
          child: ListView.builder(
            itemCount: _seasons.length,
            itemBuilder: (context, index) {
              final season = _seasons[index];
              return ListTile(
                title: Text("Saison ${season.seasonNumber}"),
                onTap: () => _onSeasonTapped(season),
                selected:
                    _selectedSeason == season, // Highlight selected season
              );
            },
          ),
        ),

        // Display Episodes of Selected Season (Optional - can be a new screen)
        if (_selectedSeason != null) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Episodes de la saison ${_selectedSeason!.seasonNumber}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedSeason!.episodes.length,
              itemBuilder: (context, index) {
                final episode = _selectedSeason!.episodes[index];
                return ListTile(
                  title: Text(episode.title),
                  // You can add an onTap for episodes too if needed
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
