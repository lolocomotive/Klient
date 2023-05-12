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

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:klient/widgets/user_avatar.dart';
import 'package:scolengo_api/scolengo_api.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key, required this.onContactSelected, this.selected}) : super(key: key);
  final Function(Contact) onContactSelected;
//ID, label
  final Map<String, String>? selected;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> c = [];
  Stream<SkolengoResponse<UsersMailSettings>>? _data;
  @override
  void initState() {
    _data = ConfigProvider.client!
        .getUsersMailSettings(ConfigProvider.credentials!.idToken.claims.subject);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      actions: [
        IconButton(
          tooltip: 'Rechercher',
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch<Contact?>(
              context: context,
              delegate: ContactsSearchDelegate(
                contacts: c,
              ),
            ).then((contact) {
              if (contact != null) widget.onContactSelected(contact);
            });
          },
        ),
      ],
      title: 'Contacts',
      child: SingleChildScrollView(
          child: StreamBuilder<SkolengoResponse<UsersMailSettings>>(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!);
          } else if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            c = snapshot.data!.data.contacts;
            c.sort((a, b) {
              if (a is PersonContact && b is PersonContact) {
                return a.person!.lastName.compareTo(b.person!.lastName);
              }
              return a is GroupContact ? -1 : 1;
            });
            for (var element in c) {
              if (element is GroupContact) {
                element.personContacts?.sort((a, b) {
                  return a.person!.lastName.compareTo(b.person!.lastName);
                });
              }
            }
            return Column(
              children: c
                  .map((contact) => ContactDisplay(
                        contact,
                        widget.onContactSelected,
                        selected: widget.selected,
                      ))
                  .toList(),
            );
          }
        },
      )),
    );
  }
}

class ContactDisplay extends StatelessWidget {
  final Contact _contact;
  final Function(Contact) onContactSelected;
  final Map<String, String>? selected;

  const ContactDisplay(this._contact, this.onContactSelected, {Key? key, this.selected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabled = !(selected?.containsKey(_contact.id) ?? false);
    final subtitleStyle =
        enabled ? TextStyle(color: Theme.of(context).colorScheme.secondary) : null;
    if (_contact is PersonContact) {
      final contact = _contact as PersonContact;
      return ListTile(
        enabled: enabled,
        leading: UserAvatar(
          contact.person!.firstName[0] + contact.person!.lastName[0],
          color: contact.person!.id.color.shade300,
        ),
        title: Text(
          contact.name ?? contact.person!.fullName,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                (contact.linksWithUser?.first.description ?? ''),
                overflow: TextOverflow.fade,
                softWrap: false,
                style: subtitleStyle,
              ),
            ),
            if (contact.linksWithUser?.first.description != null &&
                (selected?.containsKey(contact.id) ?? false))
              Container(
                width: 4 * MediaQuery.of(context).textScaleFactor,
                height: 4 * MediaQuery.of(context).textScaleFactor,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: enabled
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).disabledColor,
                  shape: BoxShape.circle,
                ),
              ),
            Text(selected?[contact.id] ?? '', style: subtitleStyle),
          ],
        ),
        onTap: () {
          onContactSelected(_contact);
        },
        trailing: selected?.containsKey(contact.id) ?? false ? const Icon(Icons.check) : null,
      );
    } else if (_contact is GroupContact) {
      final contact = _contact as GroupContact;
      final persons = contact.personContacts ?? [];
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: DefaultCard(
          padding: EdgeInsets.zero,
          child: ExpandablePanel(
            theme: ExpandableThemeData(
              iconColor: Theme.of(context).colorScheme.onBackground,
              headerAlignment: ExpandablePanelHeaderAlignment.center,
            ),
            header: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    contact.label ?? contact.id,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 17 * MediaQuery.of(context).textScaleFactor,
                    ),
                  ),
                  if (!enabled) const Icon(Icons.check),
                ],
              ),
            ),
            collapsed: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('${persons.length} personnes'),
            ),
            expanded: Column(
              children: [
                TextButton(
                  onPressed: () {
                    onContactSelected(contact);
                  },
                  child: const Text('Sélectionner tout le groupe'),
                ),
                ...persons.map((person) => ContactDisplay(
                      person,
                      onContactSelected,
                      selected: selected,
                    )),
              ],
            ),
          ),
        ),
      );
    } else {
      return ExceptionWidget(
        e: Exception('Contact type not supported: ${_contact.runtimeType.toString()}'),
        st: StackTrace.empty,
      );
    }
  }
}

class ContactsSearchDelegate extends SearchDelegate<Contact?> {
  final List<Contact> contacts;
  ContactsSearchDelegate({required this.contacts});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Vider',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final r = contacts.where(
      (element) {
        if (element is PersonContact) {
          return element.person!.fullName.toLowerCase().contains(query.toLowerCase());
        } else if (element is GroupContact) {
          return element.label!.toLowerCase().contains(query.toLowerCase());
        }
        throw Exception('Contact type not supported: ${element.runtimeType.toString()}');
      },
    ).toList();
    return ListView.builder(
      itemCount: r.length,
      itemBuilder: (context, index) {
        return ContactDisplay(r[index], (contact) {
          close(context, contact);
        });
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  @override
  String get searchFieldLabel => 'Recherche';
}
