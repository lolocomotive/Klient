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
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:klient/widgets/user_avatar.dart';
import 'package:scolengo_api/scolengo_api.dart';

//TODO support search with delegates
class ContactsPage extends StatelessWidget {
  const ContactsPage({Key? key, required this.onContactSelected}) : super(key: key);
  final Function(Contact) onContactSelected;
  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: 'Contacts',
      child: SingleChildScrollView(
          child: FutureBuilder<SkolengoResponse<UsersMailSettings>>(
        future: ConfigProvider.client!
            .getUsersMailSettings(ConfigProvider.credentials!.idToken.claims.subject),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!);
          } else if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final contacts = snapshot.data!.data.contacts;
            return Column(
              children:
                  contacts.map((contact) => ContactDisplay(contact, onContactSelected)).toList(),
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

  const ContactDisplay(this._contact, this.onContactSelected, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_contact is PersonContact) {
      final contact = _contact as PersonContact;
      return ListTile(
        leading: UserAvatar(
          contact.person!.firstName[0] + contact.person!.lastName[0],
          color: contact.person!.id.color.shade300,
        ),
        title: Text(contact.name ?? '${contact.person!.firstName} ${contact.person!.lastName}'),
        subtitle: Text(
            contact.linksWithUser?.first.description ?? contact.linksWithUser!.first.groupId ?? ''),
        onTap: () {
          onContactSelected(_contact);
        },
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
            ),
            header: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                contact.label ?? contact.id,
                style: TextStyle(
                  fontSize: 17 * MediaQuery.of(context).textScaleFactor,
                ),
              ),
            ),
            collapsed: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('${persons.length} personnes'),
            ),
            expanded: Column(
              children: persons.map((person) => ContactDisplay(person, onContactSelected)).toList(),
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
