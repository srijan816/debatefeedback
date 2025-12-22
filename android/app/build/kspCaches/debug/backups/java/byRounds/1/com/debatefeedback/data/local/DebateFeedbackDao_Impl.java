package com.debatefeedback.data.local;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityDeletionOrUpdateAdapter;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomDatabaseKt;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import com.debatefeedback.domain.model.DebateFormat;
import com.debatefeedback.domain.model.DebateSession;
import com.debatefeedback.domain.model.ProcessingStatus;
import com.debatefeedback.domain.model.SpeechRecording;
import com.debatefeedback.domain.model.Student;
import com.debatefeedback.domain.model.StudentLevel;
import com.debatefeedback.domain.model.Teacher;
import com.debatefeedback.domain.model.TeamComposition;
import com.debatefeedback.domain.model.UploadStatus;
import java.lang.Class;
import java.lang.Exception;
import java.lang.IllegalStateException;
import java.lang.Integer;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class DebateFeedbackDao_Impl implements DebateFeedbackDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<DebateSession> __insertionAdapterOfDebateSession;

  private final RoomConverters __roomConverters = new RoomConverters();

  private final EntityInsertionAdapter<Student> __insertionAdapterOfStudent;

  private final EntityInsertionAdapter<SpeechRecording> __insertionAdapterOfSpeechRecording;

  private final EntityInsertionAdapter<Teacher> __insertionAdapterOfTeacher;

  private final EntityDeletionOrUpdateAdapter<SpeechRecording> __deletionAdapterOfSpeechRecording;

  private final EntityDeletionOrUpdateAdapter<SpeechRecording> __updateAdapterOfSpeechRecording;

  private final SharedSQLiteStatement __preparedStmtOfDeleteStudentsForSession;

  private final SharedSQLiteStatement __preparedStmtOfDeleteRecordings;

  private final SharedSQLiteStatement __preparedStmtOfClearTeachers;

  public DebateFeedbackDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfDebateSession = new EntityInsertionAdapter<DebateSession>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `debate_sessions` (`id`,`motion`,`format`,`studentLevel`,`speechTimeSeconds`,`replyTimeSeconds`,`createdAt`,`isGuestMode`,`teacherId`,`classId`,`scheduleId`,`backendDebateId`,`teamComposition`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final DebateSession entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getMotion());
        final String _tmp = __roomConverters.fromFormat(entity.getFormat());
        if (_tmp == null) {
          statement.bindNull(3);
        } else {
          statement.bindString(3, _tmp);
        }
        final String _tmp_1 = __roomConverters.fromLevel(entity.getStudentLevel());
        if (_tmp_1 == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, _tmp_1);
        }
        statement.bindLong(5, entity.getSpeechTimeSeconds());
        if (entity.getReplyTimeSeconds() == null) {
          statement.bindNull(6);
        } else {
          statement.bindLong(6, entity.getReplyTimeSeconds());
        }
        statement.bindLong(7, entity.getCreatedAt());
        final int _tmp_2 = entity.isGuestMode() ? 1 : 0;
        statement.bindLong(8, _tmp_2);
        if (entity.getTeacherId() == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, entity.getTeacherId());
        }
        if (entity.getClassId() == null) {
          statement.bindNull(10);
        } else {
          statement.bindString(10, entity.getClassId());
        }
        if (entity.getScheduleId() == null) {
          statement.bindNull(11);
        } else {
          statement.bindString(11, entity.getScheduleId());
        }
        if (entity.getBackendDebateId() == null) {
          statement.bindNull(12);
        } else {
          statement.bindString(12, entity.getBackendDebateId());
        }
        final String _tmp_3 = __roomConverters.fromTeamComposition(entity.getTeamComposition());
        if (_tmp_3 == null) {
          statement.bindNull(13);
        } else {
          statement.bindString(13, _tmp_3);
        }
      }
    };
    this.__insertionAdapterOfStudent = new EntityInsertionAdapter<Student>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `students` (`id`,`name`,`level`,`createdAt`,`sessionId`) VALUES (?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final Student entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getName());
        final String _tmp = __roomConverters.fromLevel(entity.getLevel());
        if (_tmp == null) {
          statement.bindNull(3);
        } else {
          statement.bindString(3, _tmp);
        }
        statement.bindLong(4, entity.getCreatedAt());
        if (entity.getSessionId() == null) {
          statement.bindNull(5);
        } else {
          statement.bindString(5, entity.getSessionId());
        }
      }
    };
    this.__insertionAdapterOfSpeechRecording = new EntityInsertionAdapter<SpeechRecording>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `speech_recordings` (`id`,`speakerName`,`speakerPosition`,`studentId`,`localFilePath`,`durationSeconds`,`recordedAt`,`uploadStatus`,`processingStatus`,`transcriptionStatus`,`feedbackStatus`,`feedbackUrl`,`speechId`,`feedbackContent`,`transcriptUrl`,`transcriptText`,`transcriptionErrorMessage`,`feedbackErrorMessage`,`uploadProgress`,`debateSessionId`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final SpeechRecording entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getSpeakerName());
        statement.bindString(3, entity.getSpeakerPosition());
        if (entity.getStudentId() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getStudentId());
        }
        statement.bindString(5, entity.getLocalFilePath());
        statement.bindLong(6, entity.getDurationSeconds());
        statement.bindLong(7, entity.getRecordedAt());
        final String _tmp = __roomConverters.fromUploadStatus(entity.getUploadStatus());
        if (_tmp == null) {
          statement.bindNull(8);
        } else {
          statement.bindString(8, _tmp);
        }
        final String _tmp_1 = __roomConverters.fromProcessingStatus(entity.getProcessingStatus());
        if (_tmp_1 == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, _tmp_1);
        }
        final String _tmp_2 = __roomConverters.fromProcessingStatus(entity.getTranscriptionStatus());
        if (_tmp_2 == null) {
          statement.bindNull(10);
        } else {
          statement.bindString(10, _tmp_2);
        }
        final String _tmp_3 = __roomConverters.fromProcessingStatus(entity.getFeedbackStatus());
        if (_tmp_3 == null) {
          statement.bindNull(11);
        } else {
          statement.bindString(11, _tmp_3);
        }
        if (entity.getFeedbackUrl() == null) {
          statement.bindNull(12);
        } else {
          statement.bindString(12, entity.getFeedbackUrl());
        }
        if (entity.getSpeechId() == null) {
          statement.bindNull(13);
        } else {
          statement.bindString(13, entity.getSpeechId());
        }
        if (entity.getFeedbackContent() == null) {
          statement.bindNull(14);
        } else {
          statement.bindString(14, entity.getFeedbackContent());
        }
        if (entity.getTranscriptUrl() == null) {
          statement.bindNull(15);
        } else {
          statement.bindString(15, entity.getTranscriptUrl());
        }
        if (entity.getTranscriptText() == null) {
          statement.bindNull(16);
        } else {
          statement.bindString(16, entity.getTranscriptText());
        }
        if (entity.getTranscriptionErrorMessage() == null) {
          statement.bindNull(17);
        } else {
          statement.bindString(17, entity.getTranscriptionErrorMessage());
        }
        if (entity.getFeedbackErrorMessage() == null) {
          statement.bindNull(18);
        } else {
          statement.bindString(18, entity.getFeedbackErrorMessage());
        }
        statement.bindDouble(19, entity.getUploadProgress());
        statement.bindString(20, entity.getDebateSessionId());
      }
    };
    this.__insertionAdapterOfTeacher = new EntityInsertionAdapter<Teacher>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `teachers` (`id`,`name`,`deviceId`,`authToken`,`isAdmin`,`createdAt`) VALUES (?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final Teacher entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getName());
        statement.bindString(3, entity.getDeviceId());
        if (entity.getAuthToken() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getAuthToken());
        }
        final int _tmp = entity.isAdmin() ? 1 : 0;
        statement.bindLong(5, _tmp);
        statement.bindLong(6, entity.getCreatedAt());
      }
    };
    this.__deletionAdapterOfSpeechRecording = new EntityDeletionOrUpdateAdapter<SpeechRecording>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "DELETE FROM `speech_recordings` WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final SpeechRecording entity) {
        statement.bindString(1, entity.getId());
      }
    };
    this.__updateAdapterOfSpeechRecording = new EntityDeletionOrUpdateAdapter<SpeechRecording>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "UPDATE OR ABORT `speech_recordings` SET `id` = ?,`speakerName` = ?,`speakerPosition` = ?,`studentId` = ?,`localFilePath` = ?,`durationSeconds` = ?,`recordedAt` = ?,`uploadStatus` = ?,`processingStatus` = ?,`transcriptionStatus` = ?,`feedbackStatus` = ?,`feedbackUrl` = ?,`speechId` = ?,`feedbackContent` = ?,`transcriptUrl` = ?,`transcriptText` = ?,`transcriptionErrorMessage` = ?,`feedbackErrorMessage` = ?,`uploadProgress` = ?,`debateSessionId` = ? WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final SpeechRecording entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getSpeakerName());
        statement.bindString(3, entity.getSpeakerPosition());
        if (entity.getStudentId() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getStudentId());
        }
        statement.bindString(5, entity.getLocalFilePath());
        statement.bindLong(6, entity.getDurationSeconds());
        statement.bindLong(7, entity.getRecordedAt());
        final String _tmp = __roomConverters.fromUploadStatus(entity.getUploadStatus());
        if (_tmp == null) {
          statement.bindNull(8);
        } else {
          statement.bindString(8, _tmp);
        }
        final String _tmp_1 = __roomConverters.fromProcessingStatus(entity.getProcessingStatus());
        if (_tmp_1 == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, _tmp_1);
        }
        final String _tmp_2 = __roomConverters.fromProcessingStatus(entity.getTranscriptionStatus());
        if (_tmp_2 == null) {
          statement.bindNull(10);
        } else {
          statement.bindString(10, _tmp_2);
        }
        final String _tmp_3 = __roomConverters.fromProcessingStatus(entity.getFeedbackStatus());
        if (_tmp_3 == null) {
          statement.bindNull(11);
        } else {
          statement.bindString(11, _tmp_3);
        }
        if (entity.getFeedbackUrl() == null) {
          statement.bindNull(12);
        } else {
          statement.bindString(12, entity.getFeedbackUrl());
        }
        if (entity.getSpeechId() == null) {
          statement.bindNull(13);
        } else {
          statement.bindString(13, entity.getSpeechId());
        }
        if (entity.getFeedbackContent() == null) {
          statement.bindNull(14);
        } else {
          statement.bindString(14, entity.getFeedbackContent());
        }
        if (entity.getTranscriptUrl() == null) {
          statement.bindNull(15);
        } else {
          statement.bindString(15, entity.getTranscriptUrl());
        }
        if (entity.getTranscriptText() == null) {
          statement.bindNull(16);
        } else {
          statement.bindString(16, entity.getTranscriptText());
        }
        if (entity.getTranscriptionErrorMessage() == null) {
          statement.bindNull(17);
        } else {
          statement.bindString(17, entity.getTranscriptionErrorMessage());
        }
        if (entity.getFeedbackErrorMessage() == null) {
          statement.bindNull(18);
        } else {
          statement.bindString(18, entity.getFeedbackErrorMessage());
        }
        statement.bindDouble(19, entity.getUploadProgress());
        statement.bindString(20, entity.getDebateSessionId());
        statement.bindString(21, entity.getId());
      }
    };
    this.__preparedStmtOfDeleteStudentsForSession = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM students WHERE sessionId = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteRecordings = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM speech_recordings WHERE debateSessionId = ?";
        return _query;
      }
    };
    this.__preparedStmtOfClearTeachers = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM teachers";
        return _query;
      }
    };
  }

  @Override
  public Object upsertSession(final DebateSession session,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfDebateSession.insert(session);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertStudents(final List<Student> students,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfStudent.insert(students);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertRecording(final SpeechRecording recording,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfSpeechRecording.insert(recording);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertRecordings(final List<SpeechRecording> recordings,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfSpeechRecording.insert(recordings);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object upsertTeacher(final Teacher teacher, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfTeacher.insert(teacher);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteRecording(final SpeechRecording recording,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __deletionAdapterOfSpeechRecording.handle(recording);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object updateRecording(final SpeechRecording recording,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __updateAdapterOfSpeechRecording.handle(recording);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object replaceStudents(final String sessionId, final List<Student> students,
      final Continuation<? super Unit> $completion) {
    return RoomDatabaseKt.withTransaction(__db, (__cont) -> DebateFeedbackDao.DefaultImpls.replaceStudents(DebateFeedbackDao_Impl.this, sessionId, students, __cont), $completion);
  }

  @Override
  public Object replaceRecordings(final String sessionId, final List<SpeechRecording> recordings,
      final Continuation<? super Unit> $completion) {
    return RoomDatabaseKt.withTransaction(__db, (__cont) -> DebateFeedbackDao.DefaultImpls.replaceRecordings(DebateFeedbackDao_Impl.this, sessionId, recordings, __cont), $completion);
  }

  @Override
  public Object deleteStudentsForSession(final String sessionId,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteStudentsForSession.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, sessionId);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteStudentsForSession.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteRecordings(final String sessionId,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteRecordings.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, sessionId);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteRecordings.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object clearTeachers(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearTeachers.acquire();
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfClearTeachers.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<DebateSession>> observeSessions() {
    final String _sql = "SELECT * FROM debate_sessions ORDER BY createdAt DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"debate_sessions"}, new Callable<List<DebateSession>>() {
      @Override
      @NonNull
      public List<DebateSession> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfMotion = CursorUtil.getColumnIndexOrThrow(_cursor, "motion");
          final int _cursorIndexOfFormat = CursorUtil.getColumnIndexOrThrow(_cursor, "format");
          final int _cursorIndexOfStudentLevel = CursorUtil.getColumnIndexOrThrow(_cursor, "studentLevel");
          final int _cursorIndexOfSpeechTimeSeconds = CursorUtil.getColumnIndexOrThrow(_cursor, "speechTimeSeconds");
          final int _cursorIndexOfReplyTimeSeconds = CursorUtil.getColumnIndexOrThrow(_cursor, "replyTimeSeconds");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfIsGuestMode = CursorUtil.getColumnIndexOrThrow(_cursor, "isGuestMode");
          final int _cursorIndexOfTeacherId = CursorUtil.getColumnIndexOrThrow(_cursor, "teacherId");
          final int _cursorIndexOfClassId = CursorUtil.getColumnIndexOrThrow(_cursor, "classId");
          final int _cursorIndexOfScheduleId = CursorUtil.getColumnIndexOrThrow(_cursor, "scheduleId");
          final int _cursorIndexOfBackendDebateId = CursorUtil.getColumnIndexOrThrow(_cursor, "backendDebateId");
          final int _cursorIndexOfTeamComposition = CursorUtil.getColumnIndexOrThrow(_cursor, "teamComposition");
          final List<DebateSession> _result = new ArrayList<DebateSession>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final DebateSession _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpMotion;
            _tmpMotion = _cursor.getString(_cursorIndexOfMotion);
            final DebateFormat _tmpFormat;
            final String _tmp;
            if (_cursor.isNull(_cursorIndexOfFormat)) {
              _tmp = null;
            } else {
              _tmp = _cursor.getString(_cursorIndexOfFormat);
            }
            final DebateFormat _tmp_1 = __roomConverters.toFormat(_tmp);
            if (_tmp_1 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.DebateFormat', but it was NULL.");
            } else {
              _tmpFormat = _tmp_1;
            }
            final StudentLevel _tmpStudentLevel;
            final String _tmp_2;
            if (_cursor.isNull(_cursorIndexOfStudentLevel)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getString(_cursorIndexOfStudentLevel);
            }
            final StudentLevel _tmp_3 = __roomConverters.toLevel(_tmp_2);
            if (_tmp_3 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.StudentLevel', but it was NULL.");
            } else {
              _tmpStudentLevel = _tmp_3;
            }
            final int _tmpSpeechTimeSeconds;
            _tmpSpeechTimeSeconds = _cursor.getInt(_cursorIndexOfSpeechTimeSeconds);
            final Integer _tmpReplyTimeSeconds;
            if (_cursor.isNull(_cursorIndexOfReplyTimeSeconds)) {
              _tmpReplyTimeSeconds = null;
            } else {
              _tmpReplyTimeSeconds = _cursor.getInt(_cursorIndexOfReplyTimeSeconds);
            }
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            final boolean _tmpIsGuestMode;
            final int _tmp_4;
            _tmp_4 = _cursor.getInt(_cursorIndexOfIsGuestMode);
            _tmpIsGuestMode = _tmp_4 != 0;
            final String _tmpTeacherId;
            if (_cursor.isNull(_cursorIndexOfTeacherId)) {
              _tmpTeacherId = null;
            } else {
              _tmpTeacherId = _cursor.getString(_cursorIndexOfTeacherId);
            }
            final String _tmpClassId;
            if (_cursor.isNull(_cursorIndexOfClassId)) {
              _tmpClassId = null;
            } else {
              _tmpClassId = _cursor.getString(_cursorIndexOfClassId);
            }
            final String _tmpScheduleId;
            if (_cursor.isNull(_cursorIndexOfScheduleId)) {
              _tmpScheduleId = null;
            } else {
              _tmpScheduleId = _cursor.getString(_cursorIndexOfScheduleId);
            }
            final String _tmpBackendDebateId;
            if (_cursor.isNull(_cursorIndexOfBackendDebateId)) {
              _tmpBackendDebateId = null;
            } else {
              _tmpBackendDebateId = _cursor.getString(_cursorIndexOfBackendDebateId);
            }
            final TeamComposition _tmpTeamComposition;
            final String _tmp_5;
            if (_cursor.isNull(_cursorIndexOfTeamComposition)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getString(_cursorIndexOfTeamComposition);
            }
            _tmpTeamComposition = __roomConverters.toTeamComposition(_tmp_5);
            _item = new DebateSession(_tmpId,_tmpMotion,_tmpFormat,_tmpStudentLevel,_tmpSpeechTimeSeconds,_tmpReplyTimeSeconds,_tmpCreatedAt,_tmpIsGuestMode,_tmpTeacherId,_tmpClassId,_tmpScheduleId,_tmpBackendDebateId,_tmpTeamComposition);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Object getSession(final String id, final Continuation<? super DebateSession> $completion) {
    final String _sql = "SELECT * FROM debate_sessions WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<DebateSession>() {
      @Override
      @Nullable
      public DebateSession call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfMotion = CursorUtil.getColumnIndexOrThrow(_cursor, "motion");
          final int _cursorIndexOfFormat = CursorUtil.getColumnIndexOrThrow(_cursor, "format");
          final int _cursorIndexOfStudentLevel = CursorUtil.getColumnIndexOrThrow(_cursor, "studentLevel");
          final int _cursorIndexOfSpeechTimeSeconds = CursorUtil.getColumnIndexOrThrow(_cursor, "speechTimeSeconds");
          final int _cursorIndexOfReplyTimeSeconds = CursorUtil.getColumnIndexOrThrow(_cursor, "replyTimeSeconds");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfIsGuestMode = CursorUtil.getColumnIndexOrThrow(_cursor, "isGuestMode");
          final int _cursorIndexOfTeacherId = CursorUtil.getColumnIndexOrThrow(_cursor, "teacherId");
          final int _cursorIndexOfClassId = CursorUtil.getColumnIndexOrThrow(_cursor, "classId");
          final int _cursorIndexOfScheduleId = CursorUtil.getColumnIndexOrThrow(_cursor, "scheduleId");
          final int _cursorIndexOfBackendDebateId = CursorUtil.getColumnIndexOrThrow(_cursor, "backendDebateId");
          final int _cursorIndexOfTeamComposition = CursorUtil.getColumnIndexOrThrow(_cursor, "teamComposition");
          final DebateSession _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpMotion;
            _tmpMotion = _cursor.getString(_cursorIndexOfMotion);
            final DebateFormat _tmpFormat;
            final String _tmp;
            if (_cursor.isNull(_cursorIndexOfFormat)) {
              _tmp = null;
            } else {
              _tmp = _cursor.getString(_cursorIndexOfFormat);
            }
            final DebateFormat _tmp_1 = __roomConverters.toFormat(_tmp);
            if (_tmp_1 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.DebateFormat', but it was NULL.");
            } else {
              _tmpFormat = _tmp_1;
            }
            final StudentLevel _tmpStudentLevel;
            final String _tmp_2;
            if (_cursor.isNull(_cursorIndexOfStudentLevel)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getString(_cursorIndexOfStudentLevel);
            }
            final StudentLevel _tmp_3 = __roomConverters.toLevel(_tmp_2);
            if (_tmp_3 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.StudentLevel', but it was NULL.");
            } else {
              _tmpStudentLevel = _tmp_3;
            }
            final int _tmpSpeechTimeSeconds;
            _tmpSpeechTimeSeconds = _cursor.getInt(_cursorIndexOfSpeechTimeSeconds);
            final Integer _tmpReplyTimeSeconds;
            if (_cursor.isNull(_cursorIndexOfReplyTimeSeconds)) {
              _tmpReplyTimeSeconds = null;
            } else {
              _tmpReplyTimeSeconds = _cursor.getInt(_cursorIndexOfReplyTimeSeconds);
            }
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            final boolean _tmpIsGuestMode;
            final int _tmp_4;
            _tmp_4 = _cursor.getInt(_cursorIndexOfIsGuestMode);
            _tmpIsGuestMode = _tmp_4 != 0;
            final String _tmpTeacherId;
            if (_cursor.isNull(_cursorIndexOfTeacherId)) {
              _tmpTeacherId = null;
            } else {
              _tmpTeacherId = _cursor.getString(_cursorIndexOfTeacherId);
            }
            final String _tmpClassId;
            if (_cursor.isNull(_cursorIndexOfClassId)) {
              _tmpClassId = null;
            } else {
              _tmpClassId = _cursor.getString(_cursorIndexOfClassId);
            }
            final String _tmpScheduleId;
            if (_cursor.isNull(_cursorIndexOfScheduleId)) {
              _tmpScheduleId = null;
            } else {
              _tmpScheduleId = _cursor.getString(_cursorIndexOfScheduleId);
            }
            final String _tmpBackendDebateId;
            if (_cursor.isNull(_cursorIndexOfBackendDebateId)) {
              _tmpBackendDebateId = null;
            } else {
              _tmpBackendDebateId = _cursor.getString(_cursorIndexOfBackendDebateId);
            }
            final TeamComposition _tmpTeamComposition;
            final String _tmp_5;
            if (_cursor.isNull(_cursorIndexOfTeamComposition)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getString(_cursorIndexOfTeamComposition);
            }
            _tmpTeamComposition = __roomConverters.toTeamComposition(_tmp_5);
            _result = new DebateSession(_tmpId,_tmpMotion,_tmpFormat,_tmpStudentLevel,_tmpSpeechTimeSeconds,_tmpReplyTimeSeconds,_tmpCreatedAt,_tmpIsGuestMode,_tmpTeacherId,_tmpClassId,_tmpScheduleId,_tmpBackendDebateId,_tmpTeamComposition);
          } else {
            _result = null;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Object getStudentsForSession(final String sessionId,
      final Continuation<? super List<Student>> $completion) {
    final String _sql = "SELECT * FROM students WHERE sessionId = ? ORDER BY createdAt ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, sessionId);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<Student>>() {
      @Override
      @NonNull
      public List<Student> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfLevel = CursorUtil.getColumnIndexOrThrow(_cursor, "level");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfSessionId = CursorUtil.getColumnIndexOrThrow(_cursor, "sessionId");
          final List<Student> _result = new ArrayList<Student>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final Student _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final StudentLevel _tmpLevel;
            final String _tmp;
            if (_cursor.isNull(_cursorIndexOfLevel)) {
              _tmp = null;
            } else {
              _tmp = _cursor.getString(_cursorIndexOfLevel);
            }
            final StudentLevel _tmp_1 = __roomConverters.toLevel(_tmp);
            if (_tmp_1 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.StudentLevel', but it was NULL.");
            } else {
              _tmpLevel = _tmp_1;
            }
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            final String _tmpSessionId;
            if (_cursor.isNull(_cursorIndexOfSessionId)) {
              _tmpSessionId = null;
            } else {
              _tmpSessionId = _cursor.getString(_cursorIndexOfSessionId);
            }
            _item = new Student(_tmpId,_tmpName,_tmpLevel,_tmpCreatedAt,_tmpSessionId);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<SpeechRecording>> observeRecordings(final String sessionId) {
    final String _sql = "SELECT * FROM speech_recordings WHERE debateSessionId = ? ORDER BY recordedAt ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, sessionId);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"speech_recordings"}, new Callable<List<SpeechRecording>>() {
      @Override
      @NonNull
      public List<SpeechRecording> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfSpeakerName = CursorUtil.getColumnIndexOrThrow(_cursor, "speakerName");
          final int _cursorIndexOfSpeakerPosition = CursorUtil.getColumnIndexOrThrow(_cursor, "speakerPosition");
          final int _cursorIndexOfStudentId = CursorUtil.getColumnIndexOrThrow(_cursor, "studentId");
          final int _cursorIndexOfLocalFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "localFilePath");
          final int _cursorIndexOfDurationSeconds = CursorUtil.getColumnIndexOrThrow(_cursor, "durationSeconds");
          final int _cursorIndexOfRecordedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "recordedAt");
          final int _cursorIndexOfUploadStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "uploadStatus");
          final int _cursorIndexOfProcessingStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "processingStatus");
          final int _cursorIndexOfTranscriptionStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptionStatus");
          final int _cursorIndexOfFeedbackStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackStatus");
          final int _cursorIndexOfFeedbackUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackUrl");
          final int _cursorIndexOfSpeechId = CursorUtil.getColumnIndexOrThrow(_cursor, "speechId");
          final int _cursorIndexOfFeedbackContent = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackContent");
          final int _cursorIndexOfTranscriptUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptUrl");
          final int _cursorIndexOfTranscriptText = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptText");
          final int _cursorIndexOfTranscriptionErrorMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptionErrorMessage");
          final int _cursorIndexOfFeedbackErrorMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackErrorMessage");
          final int _cursorIndexOfUploadProgress = CursorUtil.getColumnIndexOrThrow(_cursor, "uploadProgress");
          final int _cursorIndexOfDebateSessionId = CursorUtil.getColumnIndexOrThrow(_cursor, "debateSessionId");
          final List<SpeechRecording> _result = new ArrayList<SpeechRecording>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final SpeechRecording _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpSpeakerName;
            _tmpSpeakerName = _cursor.getString(_cursorIndexOfSpeakerName);
            final String _tmpSpeakerPosition;
            _tmpSpeakerPosition = _cursor.getString(_cursorIndexOfSpeakerPosition);
            final String _tmpStudentId;
            if (_cursor.isNull(_cursorIndexOfStudentId)) {
              _tmpStudentId = null;
            } else {
              _tmpStudentId = _cursor.getString(_cursorIndexOfStudentId);
            }
            final String _tmpLocalFilePath;
            _tmpLocalFilePath = _cursor.getString(_cursorIndexOfLocalFilePath);
            final int _tmpDurationSeconds;
            _tmpDurationSeconds = _cursor.getInt(_cursorIndexOfDurationSeconds);
            final long _tmpRecordedAt;
            _tmpRecordedAt = _cursor.getLong(_cursorIndexOfRecordedAt);
            final UploadStatus _tmpUploadStatus;
            final String _tmp;
            if (_cursor.isNull(_cursorIndexOfUploadStatus)) {
              _tmp = null;
            } else {
              _tmp = _cursor.getString(_cursorIndexOfUploadStatus);
            }
            final UploadStatus _tmp_1 = __roomConverters.toUploadStatus(_tmp);
            if (_tmp_1 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.UploadStatus', but it was NULL.");
            } else {
              _tmpUploadStatus = _tmp_1;
            }
            final ProcessingStatus _tmpProcessingStatus;
            final String _tmp_2;
            if (_cursor.isNull(_cursorIndexOfProcessingStatus)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getString(_cursorIndexOfProcessingStatus);
            }
            final ProcessingStatus _tmp_3 = __roomConverters.toProcessingStatus(_tmp_2);
            if (_tmp_3 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.ProcessingStatus', but it was NULL.");
            } else {
              _tmpProcessingStatus = _tmp_3;
            }
            final ProcessingStatus _tmpTranscriptionStatus;
            final String _tmp_4;
            if (_cursor.isNull(_cursorIndexOfTranscriptionStatus)) {
              _tmp_4 = null;
            } else {
              _tmp_4 = _cursor.getString(_cursorIndexOfTranscriptionStatus);
            }
            final ProcessingStatus _tmp_5 = __roomConverters.toProcessingStatus(_tmp_4);
            if (_tmp_5 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.ProcessingStatus', but it was NULL.");
            } else {
              _tmpTranscriptionStatus = _tmp_5;
            }
            final ProcessingStatus _tmpFeedbackStatus;
            final String _tmp_6;
            if (_cursor.isNull(_cursorIndexOfFeedbackStatus)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getString(_cursorIndexOfFeedbackStatus);
            }
            final ProcessingStatus _tmp_7 = __roomConverters.toProcessingStatus(_tmp_6);
            if (_tmp_7 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.ProcessingStatus', but it was NULL.");
            } else {
              _tmpFeedbackStatus = _tmp_7;
            }
            final String _tmpFeedbackUrl;
            if (_cursor.isNull(_cursorIndexOfFeedbackUrl)) {
              _tmpFeedbackUrl = null;
            } else {
              _tmpFeedbackUrl = _cursor.getString(_cursorIndexOfFeedbackUrl);
            }
            final String _tmpSpeechId;
            if (_cursor.isNull(_cursorIndexOfSpeechId)) {
              _tmpSpeechId = null;
            } else {
              _tmpSpeechId = _cursor.getString(_cursorIndexOfSpeechId);
            }
            final String _tmpFeedbackContent;
            if (_cursor.isNull(_cursorIndexOfFeedbackContent)) {
              _tmpFeedbackContent = null;
            } else {
              _tmpFeedbackContent = _cursor.getString(_cursorIndexOfFeedbackContent);
            }
            final String _tmpTranscriptUrl;
            if (_cursor.isNull(_cursorIndexOfTranscriptUrl)) {
              _tmpTranscriptUrl = null;
            } else {
              _tmpTranscriptUrl = _cursor.getString(_cursorIndexOfTranscriptUrl);
            }
            final String _tmpTranscriptText;
            if (_cursor.isNull(_cursorIndexOfTranscriptText)) {
              _tmpTranscriptText = null;
            } else {
              _tmpTranscriptText = _cursor.getString(_cursorIndexOfTranscriptText);
            }
            final String _tmpTranscriptionErrorMessage;
            if (_cursor.isNull(_cursorIndexOfTranscriptionErrorMessage)) {
              _tmpTranscriptionErrorMessage = null;
            } else {
              _tmpTranscriptionErrorMessage = _cursor.getString(_cursorIndexOfTranscriptionErrorMessage);
            }
            final String _tmpFeedbackErrorMessage;
            if (_cursor.isNull(_cursorIndexOfFeedbackErrorMessage)) {
              _tmpFeedbackErrorMessage = null;
            } else {
              _tmpFeedbackErrorMessage = _cursor.getString(_cursorIndexOfFeedbackErrorMessage);
            }
            final double _tmpUploadProgress;
            _tmpUploadProgress = _cursor.getDouble(_cursorIndexOfUploadProgress);
            final String _tmpDebateSessionId;
            _tmpDebateSessionId = _cursor.getString(_cursorIndexOfDebateSessionId);
            _item = new SpeechRecording(_tmpId,_tmpSpeakerName,_tmpSpeakerPosition,_tmpStudentId,_tmpLocalFilePath,_tmpDurationSeconds,_tmpRecordedAt,_tmpUploadStatus,_tmpProcessingStatus,_tmpTranscriptionStatus,_tmpFeedbackStatus,_tmpFeedbackUrl,_tmpSpeechId,_tmpFeedbackContent,_tmpTranscriptUrl,_tmpTranscriptText,_tmpTranscriptionErrorMessage,_tmpFeedbackErrorMessage,_tmpUploadProgress,_tmpDebateSessionId);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Object getRecordings(final String sessionId,
      final Continuation<? super List<SpeechRecording>> $completion) {
    final String _sql = "SELECT * FROM speech_recordings WHERE debateSessionId = ? ORDER BY recordedAt ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, sessionId);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<SpeechRecording>>() {
      @Override
      @NonNull
      public List<SpeechRecording> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfSpeakerName = CursorUtil.getColumnIndexOrThrow(_cursor, "speakerName");
          final int _cursorIndexOfSpeakerPosition = CursorUtil.getColumnIndexOrThrow(_cursor, "speakerPosition");
          final int _cursorIndexOfStudentId = CursorUtil.getColumnIndexOrThrow(_cursor, "studentId");
          final int _cursorIndexOfLocalFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "localFilePath");
          final int _cursorIndexOfDurationSeconds = CursorUtil.getColumnIndexOrThrow(_cursor, "durationSeconds");
          final int _cursorIndexOfRecordedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "recordedAt");
          final int _cursorIndexOfUploadStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "uploadStatus");
          final int _cursorIndexOfProcessingStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "processingStatus");
          final int _cursorIndexOfTranscriptionStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptionStatus");
          final int _cursorIndexOfFeedbackStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackStatus");
          final int _cursorIndexOfFeedbackUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackUrl");
          final int _cursorIndexOfSpeechId = CursorUtil.getColumnIndexOrThrow(_cursor, "speechId");
          final int _cursorIndexOfFeedbackContent = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackContent");
          final int _cursorIndexOfTranscriptUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptUrl");
          final int _cursorIndexOfTranscriptText = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptText");
          final int _cursorIndexOfTranscriptionErrorMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "transcriptionErrorMessage");
          final int _cursorIndexOfFeedbackErrorMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "feedbackErrorMessage");
          final int _cursorIndexOfUploadProgress = CursorUtil.getColumnIndexOrThrow(_cursor, "uploadProgress");
          final int _cursorIndexOfDebateSessionId = CursorUtil.getColumnIndexOrThrow(_cursor, "debateSessionId");
          final List<SpeechRecording> _result = new ArrayList<SpeechRecording>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final SpeechRecording _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpSpeakerName;
            _tmpSpeakerName = _cursor.getString(_cursorIndexOfSpeakerName);
            final String _tmpSpeakerPosition;
            _tmpSpeakerPosition = _cursor.getString(_cursorIndexOfSpeakerPosition);
            final String _tmpStudentId;
            if (_cursor.isNull(_cursorIndexOfStudentId)) {
              _tmpStudentId = null;
            } else {
              _tmpStudentId = _cursor.getString(_cursorIndexOfStudentId);
            }
            final String _tmpLocalFilePath;
            _tmpLocalFilePath = _cursor.getString(_cursorIndexOfLocalFilePath);
            final int _tmpDurationSeconds;
            _tmpDurationSeconds = _cursor.getInt(_cursorIndexOfDurationSeconds);
            final long _tmpRecordedAt;
            _tmpRecordedAt = _cursor.getLong(_cursorIndexOfRecordedAt);
            final UploadStatus _tmpUploadStatus;
            final String _tmp;
            if (_cursor.isNull(_cursorIndexOfUploadStatus)) {
              _tmp = null;
            } else {
              _tmp = _cursor.getString(_cursorIndexOfUploadStatus);
            }
            final UploadStatus _tmp_1 = __roomConverters.toUploadStatus(_tmp);
            if (_tmp_1 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.UploadStatus', but it was NULL.");
            } else {
              _tmpUploadStatus = _tmp_1;
            }
            final ProcessingStatus _tmpProcessingStatus;
            final String _tmp_2;
            if (_cursor.isNull(_cursorIndexOfProcessingStatus)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getString(_cursorIndexOfProcessingStatus);
            }
            final ProcessingStatus _tmp_3 = __roomConverters.toProcessingStatus(_tmp_2);
            if (_tmp_3 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.ProcessingStatus', but it was NULL.");
            } else {
              _tmpProcessingStatus = _tmp_3;
            }
            final ProcessingStatus _tmpTranscriptionStatus;
            final String _tmp_4;
            if (_cursor.isNull(_cursorIndexOfTranscriptionStatus)) {
              _tmp_4 = null;
            } else {
              _tmp_4 = _cursor.getString(_cursorIndexOfTranscriptionStatus);
            }
            final ProcessingStatus _tmp_5 = __roomConverters.toProcessingStatus(_tmp_4);
            if (_tmp_5 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.ProcessingStatus', but it was NULL.");
            } else {
              _tmpTranscriptionStatus = _tmp_5;
            }
            final ProcessingStatus _tmpFeedbackStatus;
            final String _tmp_6;
            if (_cursor.isNull(_cursorIndexOfFeedbackStatus)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getString(_cursorIndexOfFeedbackStatus);
            }
            final ProcessingStatus _tmp_7 = __roomConverters.toProcessingStatus(_tmp_6);
            if (_tmp_7 == null) {
              throw new IllegalStateException("Expected NON-NULL 'com.debatefeedback.domain.model.ProcessingStatus', but it was NULL.");
            } else {
              _tmpFeedbackStatus = _tmp_7;
            }
            final String _tmpFeedbackUrl;
            if (_cursor.isNull(_cursorIndexOfFeedbackUrl)) {
              _tmpFeedbackUrl = null;
            } else {
              _tmpFeedbackUrl = _cursor.getString(_cursorIndexOfFeedbackUrl);
            }
            final String _tmpSpeechId;
            if (_cursor.isNull(_cursorIndexOfSpeechId)) {
              _tmpSpeechId = null;
            } else {
              _tmpSpeechId = _cursor.getString(_cursorIndexOfSpeechId);
            }
            final String _tmpFeedbackContent;
            if (_cursor.isNull(_cursorIndexOfFeedbackContent)) {
              _tmpFeedbackContent = null;
            } else {
              _tmpFeedbackContent = _cursor.getString(_cursorIndexOfFeedbackContent);
            }
            final String _tmpTranscriptUrl;
            if (_cursor.isNull(_cursorIndexOfTranscriptUrl)) {
              _tmpTranscriptUrl = null;
            } else {
              _tmpTranscriptUrl = _cursor.getString(_cursorIndexOfTranscriptUrl);
            }
            final String _tmpTranscriptText;
            if (_cursor.isNull(_cursorIndexOfTranscriptText)) {
              _tmpTranscriptText = null;
            } else {
              _tmpTranscriptText = _cursor.getString(_cursorIndexOfTranscriptText);
            }
            final String _tmpTranscriptionErrorMessage;
            if (_cursor.isNull(_cursorIndexOfTranscriptionErrorMessage)) {
              _tmpTranscriptionErrorMessage = null;
            } else {
              _tmpTranscriptionErrorMessage = _cursor.getString(_cursorIndexOfTranscriptionErrorMessage);
            }
            final String _tmpFeedbackErrorMessage;
            if (_cursor.isNull(_cursorIndexOfFeedbackErrorMessage)) {
              _tmpFeedbackErrorMessage = null;
            } else {
              _tmpFeedbackErrorMessage = _cursor.getString(_cursorIndexOfFeedbackErrorMessage);
            }
            final double _tmpUploadProgress;
            _tmpUploadProgress = _cursor.getDouble(_cursorIndexOfUploadProgress);
            final String _tmpDebateSessionId;
            _tmpDebateSessionId = _cursor.getString(_cursorIndexOfDebateSessionId);
            _item = new SpeechRecording(_tmpId,_tmpSpeakerName,_tmpSpeakerPosition,_tmpStudentId,_tmpLocalFilePath,_tmpDurationSeconds,_tmpRecordedAt,_tmpUploadStatus,_tmpProcessingStatus,_tmpTranscriptionStatus,_tmpFeedbackStatus,_tmpFeedbackUrl,_tmpSpeechId,_tmpFeedbackContent,_tmpTranscriptUrl,_tmpTranscriptText,_tmpTranscriptionErrorMessage,_tmpFeedbackErrorMessage,_tmpUploadProgress,_tmpDebateSessionId);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Object getTeacher(final String id, final Continuation<? super Teacher> $completion) {
    final String _sql = "SELECT * FROM teachers WHERE id = ? LIMIT 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<Teacher>() {
      @Override
      @Nullable
      public Teacher call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfDeviceId = CursorUtil.getColumnIndexOrThrow(_cursor, "deviceId");
          final int _cursorIndexOfAuthToken = CursorUtil.getColumnIndexOrThrow(_cursor, "authToken");
          final int _cursorIndexOfIsAdmin = CursorUtil.getColumnIndexOrThrow(_cursor, "isAdmin");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final Teacher _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final String _tmpDeviceId;
            _tmpDeviceId = _cursor.getString(_cursorIndexOfDeviceId);
            final String _tmpAuthToken;
            if (_cursor.isNull(_cursorIndexOfAuthToken)) {
              _tmpAuthToken = null;
            } else {
              _tmpAuthToken = _cursor.getString(_cursorIndexOfAuthToken);
            }
            final boolean _tmpIsAdmin;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfIsAdmin);
            _tmpIsAdmin = _tmp != 0;
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _result = new Teacher(_tmpId,_tmpName,_tmpDeviceId,_tmpAuthToken,_tmpIsAdmin,_tmpCreatedAt);
          } else {
            _result = null;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
