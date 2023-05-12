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

import 'dart:developer';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/screens/contacts.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/custom_html.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/delayed_progress_indicator.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:scolengo_api/scolengo_api.dart';

class NewCommunicationPage extends StatefulWidget {
  const NewCommunicationPage({Key? key}) : super(key: key);

  @override
  State<NewCommunicationPage> createState() => _NewCommunicationPageState();
}

class _NewCommunicationPageState extends State<NewCommunicationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _appendSignature = true;
  String _subj = '';
  String _contentText = '';
  List<Contact> _recipients = [];
  List<Contact> _ccRecipients = [];
  List<Contact> _bccRecipients = [];
  Stream<SkolengoResponse<UsersMailSettings>>? _mailSettings;
  @override
  void initState() {
    _mailSettings = ConfigProvider.client!
        .getUsersMailSettings(ConfigProvider.credentials!.idToken.claims.subject);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      actions: [IconButton(onPressed: send, icon: const Icon(Icons.send))],
      title: 'Nouveau message',
      child: SingleChildScrollView(
        child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (_recipients.isEmpty) {
                        return 'Vous devez sélectionner au moins un destinataire';
                      }
                      return null;
                    },
                    builder: (state) => DefaultCard(
                      child: RecipientList(
                        onUpdate: (recipients) {
                          _recipients = (recipients);
                          state.validate();
                        },
                        title: 'À',
                        recipients: _recipients,
                        ccRecipients: _ccRecipients,
                        bccRecipients: _bccRecipients,
                        titleSize: 16,
                        hasError: state.hasError,
                        errorText: state.errorText,
                      ),
                    ),
                  ),
                  DefaultCard(
                    padding: EdgeInsets.zero,
                    child: ExpandablePanel(
                      theme: ExpandableThemeData(
                        iconColor: Theme.of(context).colorScheme.primary,
                        headerAlignment: ExpandablePanelHeaderAlignment.center,
                      ),
                      header: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'CC/CCI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: MediaQuery.of(context).textScaleFactor * 16,
                          ),
                        ),
                      ),
                      collapsed: Container(),
                      expanded: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            RecipientList(
                              onUpdate: (recipients) {
                                _ccRecipients = recipients;
                                setState(() {});
                              },
                              title: 'CC',
                              recipients: _recipients,
                              ccRecipients: _ccRecipients,
                              bccRecipients: _bccRecipients,
                            ),
                            const Divider(),
                            RecipientList(
                              onUpdate: (recipients) {
                                _bccRecipients = recipients;
                                setState(() {});
                              },
                              title: 'CCI',
                              recipients: _recipients,
                              ccRecipients: _ccRecipients,
                              bccRecipients: _bccRecipients,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DefaultCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Contenu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: MediaQuery.of(context).textScaleFactor * 16,
                          ),
                        ),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'L\'objet ne peut pas être vide';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(labelText: 'Objet'),
                          onChanged: (value) {
                            _subj = value;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le contenu ne peut pas être vide';
                              }
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: 'Contenu',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.multiline,
                            expands: false,
                            onChanged: (value) {
                              _contentText = value;
                            },
                            maxLines: 6,
                          ),
                        ),
                        Row(
                          children: [
                            const Text('Signature'),
                            Checkbox(
                                value: _appendSignature,
                                onChanged: (value) {
                                  _appendSignature = value ?? false;
                                  setState(() {});
                                }),
                          ],
                        ),
                        if (_appendSignature)
                          StreamBuilder<SkolengoResponse<UsersMailSettings>>(
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return ExceptionWidget(
                                    e: snapshot.error!, st: snapshot.stackTrace!);
                              } else if (snapshot.hasData) {
                                return CustomHtml(data: snapshot.data!.data.signature.content);
                              } else {
                                return const DelayedProgressIndicator(
                                  delay: Duration(milliseconds: 500),
                                );
                              }
                            },
                            stream: _mailSettings,
                          ),
                        ElevatedButton.icon(
                          onPressed: send,
                          icon: const Icon(Icons.send),
                          label: const Text('Envoyer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ElevationOverlay.applySurfaceTint(
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.primary,
                                4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  send() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      String contentHtml = _contentText.replaceAll('\n', '<br/>');
      if (_appendSignature) {
        final response = await ConfigProvider.client!
            .getUsersMailSettings(ConfigProvider.credentials!.idToken.claims.subject)
            .first;
        contentHtml +=
            "<div style='padding-top: 5px;'> <div><br>${response.data.signature.content}</div></div>";
      }
      final response = await ConfigProvider.client!.postCommunication(
        _subj,
        contentHtml,
        _recipients,
        ccRecipients: _ccRecipients.isEmpty ? null : _ccRecipients,
        bccRecipients: _bccRecipients.isEmpty ? null : _bccRecipients,
      );
      inspect(response);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      Util.onException(e, st);
    }
  }
}

class RecipientList extends StatefulWidget {
  final bool hasError;
  final String? errorText;

  const RecipientList({
    Key? key,
    required this.onUpdate,
    required this.title,
    this.titleSize,
    this.hasError = false,
    this.errorText,
    required this.recipients,
    required this.ccRecipients,
    required this.bccRecipients,
  }) : super(key: key);
  final Function(List<Contact>) onUpdate;
  final String title;
  final double? titleSize;
  final List<Contact> recipients;
  final List<Contact> ccRecipients;
  final List<Contact> bccRecipients;

  @override
  State<RecipientList> createState() => _RecipientListState();
}

class _RecipientListState extends State<RecipientList> {
  final List<Contact> _contacts = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: widget.titleSize == null
                ? null
                : MediaQuery.of(context).textScaleFactor * widget.titleSize!,
          ),
        ),
        Wrap(
          spacing: 8,
          children: _contacts
              .map(
                (contact) => ContactChip(
                    contact: contact,
                    onRemove: () {
                      _contacts.remove(contact);
                      widget.onUpdate(_contacts);
                      setState(() {});
                    }),
              )
              .toList(),
        ),
        if (widget.hasError)
          Text(
            widget.errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        IconButton(
            tooltip: 'Ajouter un destinataire',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactsPage(
                    onContactSelected: (contact) {
                      if (_contacts.where((element) => element.id == contact.id).isEmpty) {
                        _contacts.add(contact);
                        widget.onUpdate(_contacts);
                      }
                      Navigator.of(context).pop();
                    },
                    selected: Map.fromEntries([
                      ...widget.recipients.map((e) => MapEntry(e.id, 'À')),
                      ...widget.ccRecipients.map((e) => MapEntry(e.id, 'CC')),
                      ...widget.bccRecipients.map((e) => MapEntry(e.id, 'CCI')),
                    ]),
                  ),
                ),
              );
              setState(() {});
            },
            icon: const Icon(Icons.add)),
      ],
    );
  }
}

class ContactChip extends StatelessWidget {
  const ContactChip({Key? key, required this.contact, required this.onRemove}) : super(key: key);
  final Contact contact;
  final Function() onRemove;
  @override
  Widget build(BuildContext context) {
    if (contact is PersonContact) {
      final c = contact as PersonContact;
      return Chip(
        surfaceTintColor: c.person!.id.color.shade200,
        side: BorderSide(color: c.person!.id.color.shade200),
        elevation: 8,
        label: Text(c.person!.fullName),
        key: ObjectKey(contact.id),
        onDeleted: onRemove,
      );
    } else if (contact is GroupContact) {
      final c = contact as GroupContact;
      return Chip(
        surfaceTintColor: c.id.color.shade200,
        side: BorderSide(color: c.id.color.shade200),
        elevation: 8,
        label: Text('${c.label}'),
        key: ObjectKey(contact.id),
        onDeleted: onRemove,
      );
    } else {
      return ExceptionWidget(
          e: Exception('Contact type ${contact.runtimeType} not supported'), st: StackTrace.empty);
    }
  }
}
