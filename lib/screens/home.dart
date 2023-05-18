/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
 *
 * Copyright (C) 2022 lolocomotive
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:klient/api/custom_requests.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:klient/widgets/delayed_progress_indicator.dart';
import 'package:klient/widgets/evaluation_card.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:klient/widgets/exercise_card.dart';
import 'package:klient/widgets/school_info_card.dart';
import 'package:klient/widgets/user_avatar_action.dart';
import 'package:scolengo_api/scolengo_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<_HomeworkListWrapperState> _hKey = GlobalKey();
  final GlobalKey<_GradeListState> _gKey = GlobalKey();
  final GlobalKey<_ArticleListState> _aKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: 'Acceuil',
      actions: [
        UserAvatarAction(
          onUpdate: () {
            if (_gKey.currentState != null) {
              _gKey.currentState!.setState(() {});
            }
            _aKey.currentState!.setState(() {});
            _hKey.currentState!.setState(() {});
          },
        )
      ],
      child: RefreshIndicator(
        onRefresh: (() async {
          KlientApp.cache.forceRefresh = true;
          await Future.wait(<Future>[
            getHomework().last.then((_) => _hKey.currentState?.setState(() {})),
            getEvaluationsAsTable().last.then((_) => _gKey.currentState?.setState(() {})),
            ConfigProvider.client!
                .getSchoolInfos()
                .last
                .then((_) => _aKey.currentState?.setState(() {})),
          ]);
          KlientApp.cache.forceRefresh = false;
        }),
        child: SingleChildScrollView(
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 1200) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('Travail à faire'),
                        HomeworkListWrapper(key: _hKey),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GradeList(key: _gKey),
                      ],
                    ),
                  ),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle('Actualités'),
                      ArticleList(key: _aKey),
                    ],
                  ))
                ],
              );
            }
            if (constraints.maxWidth < 700) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Travail à faire'),
                  HomeworkListWrapper(key: _hKey),
                  GradeList(key: _gKey),
                  const SectionTitle('Actualités'),
                  ArticleList(key: _aKey),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle('Travail à faire'),
                      HomeworkListWrapper(key: _hKey),
                      GradeList(key: _gKey),
                    ],
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Actualités'),
                    ArticleList(key: _aKey),
                  ],
                ))
              ],
            );
          }),
        ),
      ),
    );
  }
}

class HomeworkListWrapper extends StatefulWidget {
  const HomeworkListWrapper({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeworkListWrapper> createState() => _HomeworkListWrapperState();
}

class _HomeworkListWrapperState extends State<HomeworkListWrapper> with TickerProviderStateMixin {
  bool loaded = false;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeworkAssignment>>(
        stream: getHomework(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: DelayedProgressIndicator(
                  delay: Duration(milliseconds: 500),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return DefaultCard(
                child: ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!));
          }

          return snapshot.data!.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                      child: Text(
                    'Rien à afficher',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  )),
                )
              : DefaultTransition(
                  animate: !loaded,
                  child: Builder(builder: (context) {
                    loaded = true;
                    return HomeworkList(data: snapshot.data!);
                  }),
                );
        });
  }
}

class GradeList extends StatefulWidget {
  const GradeList({
    Key? key,
  }) : super(key: key);

  @override
  State<GradeList> createState() => _GradeListState();
}

class _GradeListState extends State<GradeList> with TickerProviderStateMixin {
  bool loaded = false;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
        future: ConfigProvider.user,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!);
          }
          if (!snapshot.hasData) {
            return const Center(
              child: DelayedProgressIndicator(
                delay: Duration(milliseconds: 500),
              ),
            );
          }

          if (snapshot.data!.permissions!
              .where(
                (permission) =>
                    permission.schoolId ==
                        (ConfigProvider.currentSchool ?? ConfigProvider.school!.id) &&
                    permission.service == 'EVAL' &&
                    permission.permittedOperations.contains('READ_EVALUATIONS'),
              )
              .isEmpty) return Container();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Dernières notes'),
              StreamBuilder<List<List<Evaluation>>>(
                  stream: getEvaluationsAsTable(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: DelayedProgressIndicator(
                            delay: Duration(milliseconds: 500),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return DefaultCard(
                          child: ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!));
                    }
                    return DefaultTransition(
                      animate: !loaded,
                      child: Builder(builder: (context) {
                        loaded = true;
                        return snapshot.data!.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(
                                  'Rien à afficher',
                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                )),
                              )
                            : SizedBox(
                                child: Column(
                                  children: snapshot.data!
                                      .map(
                                        (twoGrades) => Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            EvaluationCard(
                                              twoGrades[0],
                                              compact: ConfigProvider.compact!,
                                            ),
                                            if (twoGrades.length > 1)
                                              EvaluationCard(
                                                twoGrades[1],
                                                compact: ConfigProvider.compact!,
                                              )
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                      }),
                    );
                  }),
            ],
          );
        });
  }
}

class ArticleList extends StatefulWidget {
  const ArticleList({
    Key? key,
  }) : super(key: key);

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> with TickerProviderStateMixin {
  bool loaded = false;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SkolengoResponse<List<SchoolInfo>>>(
        stream: ConfigProvider.client!.getSchoolInfos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: DelayedProgressIndicator(
                  delay: Duration(milliseconds: 500),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: DefaultCard(
                  child: ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!),
                ),
              ),
            );
          }
          return DefaultTransition(
            animate: !loaded,
            child: Builder(builder: (context) {
              loaded = true;
              return snapshot.data!.data.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'Rien à afficher',
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children:
                          snapshot.data!.data.map((article) => SchoolInfoCard(article)).toList(),
                    );
            }),
          );
        });
  }
}

class SectionTitle extends StatelessWidget {
  final String _title;
  const SectionTitle(
    this._title, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 8),
      child: Text(
        _title,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}

class HomeworkList extends StatefulWidget {
  const HomeworkList({
    Key? key,
    required List<HomeworkAssignment> data,
  })  : _data = data,
        super(key: key);

  final List<HomeworkAssignment> _data;

  @override
  State<HomeworkList> createState() => _HomeworkListState();
}

class _HomeworkListState extends State<HomeworkList> {
  bool _showDone = false;

  List<HomeworkAssignment>? mutableData;
  @override
  Widget build(BuildContext context) {
    mutableData ??= widget._data;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: InkWell(
          onTap: () {
            setState(() {
              _showDone = !_showDone;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: Semantics(
              checked: _showDone,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Afficher le travail fait'),
                  Switch(
                      value: _showDone,
                      onChanged: (value) {
                        setState(() {
                          _showDone = value;
                        });
                      }),
                ],
              ),
            ),
          ),
        ),
      ),
      if (widget._data.where((element) => element.done == false).isEmpty && !_showDone)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            'Tout a été fait :)',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          )),
        )
      else
        ...mutableData!.map((homework) {
          if (!_showDone && homework.done) {
            return Container();
          }
          return Opacity(
            opacity: homework.done ? .6 : 1,
            child: HomeworkCard(
              homework,
              compact: ConfigProvider.compact!,
              elevation: 1,
              showDate: true,
              showSubject: true,
              onMarkedDone: (bool done) {
                mutableData!.remove(homework);
                HomeworkAssignment modified = (homework..done = done);
                mutableData!.add(modified);
                mutableData!.sort(
                  (a, b) =>
                      a.dueDateTime.date().millisecondsSinceEpoch -
                      b.dueDateTime.date().millisecondsSinceEpoch,
                );
                setState(() {});
              },
            ),
          );
        }).toList(),
    ]);
  }
}
