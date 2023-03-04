/*
 * This file is part of the Kosmos Client (https://github.com/lolocomotive/kosmos_client)
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

import 'package:kosmos_client/api/attachment.dart';
import 'package:kosmos_client/api/exercise.dart';

/// An attachment that is linked to a [Exercise] (only it's id to avoid circular
/// references though)
class ExerciseAttachment extends Attachment {
  int id;

  /// The ID of the [Exercise] this attachment belongs to
  int parentID;
  String url;
  @override
  String name;

  ExerciseAttachment(this.id, this.parentID, this.url, this.name);

  static ExerciseAttachment parse(Map<String, dynamic> result) {
    return ExerciseAttachment(
      result['ExerciseAttachmentID'] as int? ?? result['ID'] as int,
      result['ParentID'],
      result['URL'] as String,
      result['Name'] as String,
    );
  }
}
