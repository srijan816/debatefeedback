package com.debatefeedback.data.local;

import androidx.annotation.NonNull;
import androidx.room.DatabaseConfiguration;
import androidx.room.InvalidationTracker;
import androidx.room.RoomDatabase;
import androidx.room.RoomOpenHelper;
import androidx.room.migration.AutoMigrationSpec;
import androidx.room.migration.Migration;
import androidx.room.util.DBUtil;
import androidx.room.util.TableInfo;
import androidx.sqlite.db.SupportSQLiteDatabase;
import androidx.sqlite.db.SupportSQLiteOpenHelper;
import java.lang.Class;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class DebateFeedbackDatabase_Impl extends DebateFeedbackDatabase {
  private volatile DebateFeedbackDao _debateFeedbackDao;

  @Override
  @NonNull
  protected SupportSQLiteOpenHelper createOpenHelper(@NonNull final DatabaseConfiguration config) {
    final SupportSQLiteOpenHelper.Callback _openCallback = new RoomOpenHelper(config, new RoomOpenHelper.Delegate(1) {
      @Override
      public void createAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS `teachers` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `deviceId` TEXT NOT NULL, `authToken` TEXT, `isAdmin` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `students` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `level` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `sessionId` TEXT, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `debate_sessions` (`id` TEXT NOT NULL, `motion` TEXT NOT NULL, `format` TEXT NOT NULL, `studentLevel` TEXT NOT NULL, `speechTimeSeconds` INTEGER NOT NULL, `replyTimeSeconds` INTEGER, `createdAt` INTEGER NOT NULL, `isGuestMode` INTEGER NOT NULL, `teacherId` TEXT, `classId` TEXT, `scheduleId` TEXT, `backendDebateId` TEXT, `teamComposition` TEXT, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `speech_recordings` (`id` TEXT NOT NULL, `speakerName` TEXT NOT NULL, `speakerPosition` TEXT NOT NULL, `studentId` TEXT, `localFilePath` TEXT NOT NULL, `durationSeconds` INTEGER NOT NULL, `recordedAt` INTEGER NOT NULL, `uploadStatus` TEXT NOT NULL, `processingStatus` TEXT NOT NULL, `transcriptionStatus` TEXT NOT NULL, `feedbackStatus` TEXT NOT NULL, `feedbackUrl` TEXT, `speechId` TEXT, `feedbackContent` TEXT, `transcriptUrl` TEXT, `transcriptText` TEXT, `transcriptionErrorMessage` TEXT, `feedbackErrorMessage` TEXT, `uploadProgress` REAL NOT NULL, `debateSessionId` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)");
        db.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, '2ea67e3f62b4a7392ce60481636118ca')");
      }

      @Override
      public void dropAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("DROP TABLE IF EXISTS `teachers`");
        db.execSQL("DROP TABLE IF EXISTS `students`");
        db.execSQL("DROP TABLE IF EXISTS `debate_sessions`");
        db.execSQL("DROP TABLE IF EXISTS `speech_recordings`");
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onDestructiveMigration(db);
          }
        }
      }

      @Override
      public void onCreate(@NonNull final SupportSQLiteDatabase db) {
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onCreate(db);
          }
        }
      }

      @Override
      public void onOpen(@NonNull final SupportSQLiteDatabase db) {
        mDatabase = db;
        internalInitInvalidationTracker(db);
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onOpen(db);
          }
        }
      }

      @Override
      public void onPreMigrate(@NonNull final SupportSQLiteDatabase db) {
        DBUtil.dropFtsSyncTriggers(db);
      }

      @Override
      public void onPostMigrate(@NonNull final SupportSQLiteDatabase db) {
      }

      @Override
      @NonNull
      public RoomOpenHelper.ValidationResult onValidateSchema(
          @NonNull final SupportSQLiteDatabase db) {
        final HashMap<String, TableInfo.Column> _columnsTeachers = new HashMap<String, TableInfo.Column>(6);
        _columnsTeachers.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTeachers.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTeachers.put("deviceId", new TableInfo.Column("deviceId", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTeachers.put("authToken", new TableInfo.Column("authToken", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTeachers.put("isAdmin", new TableInfo.Column("isAdmin", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTeachers.put("createdAt", new TableInfo.Column("createdAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysTeachers = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesTeachers = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoTeachers = new TableInfo("teachers", _columnsTeachers, _foreignKeysTeachers, _indicesTeachers);
        final TableInfo _existingTeachers = TableInfo.read(db, "teachers");
        if (!_infoTeachers.equals(_existingTeachers)) {
          return new RoomOpenHelper.ValidationResult(false, "teachers(com.debatefeedback.domain.model.Teacher).\n"
                  + " Expected:\n" + _infoTeachers + "\n"
                  + " Found:\n" + _existingTeachers);
        }
        final HashMap<String, TableInfo.Column> _columnsStudents = new HashMap<String, TableInfo.Column>(5);
        _columnsStudents.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsStudents.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsStudents.put("level", new TableInfo.Column("level", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsStudents.put("createdAt", new TableInfo.Column("createdAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsStudents.put("sessionId", new TableInfo.Column("sessionId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysStudents = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesStudents = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoStudents = new TableInfo("students", _columnsStudents, _foreignKeysStudents, _indicesStudents);
        final TableInfo _existingStudents = TableInfo.read(db, "students");
        if (!_infoStudents.equals(_existingStudents)) {
          return new RoomOpenHelper.ValidationResult(false, "students(com.debatefeedback.domain.model.Student).\n"
                  + " Expected:\n" + _infoStudents + "\n"
                  + " Found:\n" + _existingStudents);
        }
        final HashMap<String, TableInfo.Column> _columnsDebateSessions = new HashMap<String, TableInfo.Column>(13);
        _columnsDebateSessions.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("motion", new TableInfo.Column("motion", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("format", new TableInfo.Column("format", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("studentLevel", new TableInfo.Column("studentLevel", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("speechTimeSeconds", new TableInfo.Column("speechTimeSeconds", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("replyTimeSeconds", new TableInfo.Column("replyTimeSeconds", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("createdAt", new TableInfo.Column("createdAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("isGuestMode", new TableInfo.Column("isGuestMode", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("teacherId", new TableInfo.Column("teacherId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("classId", new TableInfo.Column("classId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("scheduleId", new TableInfo.Column("scheduleId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("backendDebateId", new TableInfo.Column("backendDebateId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsDebateSessions.put("teamComposition", new TableInfo.Column("teamComposition", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysDebateSessions = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesDebateSessions = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoDebateSessions = new TableInfo("debate_sessions", _columnsDebateSessions, _foreignKeysDebateSessions, _indicesDebateSessions);
        final TableInfo _existingDebateSessions = TableInfo.read(db, "debate_sessions");
        if (!_infoDebateSessions.equals(_existingDebateSessions)) {
          return new RoomOpenHelper.ValidationResult(false, "debate_sessions(com.debatefeedback.domain.model.DebateSession).\n"
                  + " Expected:\n" + _infoDebateSessions + "\n"
                  + " Found:\n" + _existingDebateSessions);
        }
        final HashMap<String, TableInfo.Column> _columnsSpeechRecordings = new HashMap<String, TableInfo.Column>(20);
        _columnsSpeechRecordings.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("speakerName", new TableInfo.Column("speakerName", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("speakerPosition", new TableInfo.Column("speakerPosition", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("studentId", new TableInfo.Column("studentId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("localFilePath", new TableInfo.Column("localFilePath", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("durationSeconds", new TableInfo.Column("durationSeconds", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("recordedAt", new TableInfo.Column("recordedAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("uploadStatus", new TableInfo.Column("uploadStatus", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("processingStatus", new TableInfo.Column("processingStatus", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("transcriptionStatus", new TableInfo.Column("transcriptionStatus", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("feedbackStatus", new TableInfo.Column("feedbackStatus", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("feedbackUrl", new TableInfo.Column("feedbackUrl", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("speechId", new TableInfo.Column("speechId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("feedbackContent", new TableInfo.Column("feedbackContent", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("transcriptUrl", new TableInfo.Column("transcriptUrl", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("transcriptText", new TableInfo.Column("transcriptText", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("transcriptionErrorMessage", new TableInfo.Column("transcriptionErrorMessage", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("feedbackErrorMessage", new TableInfo.Column("feedbackErrorMessage", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("uploadProgress", new TableInfo.Column("uploadProgress", "REAL", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSpeechRecordings.put("debateSessionId", new TableInfo.Column("debateSessionId", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysSpeechRecordings = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesSpeechRecordings = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoSpeechRecordings = new TableInfo("speech_recordings", _columnsSpeechRecordings, _foreignKeysSpeechRecordings, _indicesSpeechRecordings);
        final TableInfo _existingSpeechRecordings = TableInfo.read(db, "speech_recordings");
        if (!_infoSpeechRecordings.equals(_existingSpeechRecordings)) {
          return new RoomOpenHelper.ValidationResult(false, "speech_recordings(com.debatefeedback.domain.model.SpeechRecording).\n"
                  + " Expected:\n" + _infoSpeechRecordings + "\n"
                  + " Found:\n" + _existingSpeechRecordings);
        }
        return new RoomOpenHelper.ValidationResult(true, null);
      }
    }, "2ea67e3f62b4a7392ce60481636118ca", "82925da9e120fcfd84d29ccf594f3fa4");
    final SupportSQLiteOpenHelper.Configuration _sqliteConfig = SupportSQLiteOpenHelper.Configuration.builder(config.context).name(config.name).callback(_openCallback).build();
    final SupportSQLiteOpenHelper _helper = config.sqliteOpenHelperFactory.create(_sqliteConfig);
    return _helper;
  }

  @Override
  @NonNull
  protected InvalidationTracker createInvalidationTracker() {
    final HashMap<String, String> _shadowTablesMap = new HashMap<String, String>(0);
    final HashMap<String, Set<String>> _viewTables = new HashMap<String, Set<String>>(0);
    return new InvalidationTracker(this, _shadowTablesMap, _viewTables, "teachers","students","debate_sessions","speech_recordings");
  }

  @Override
  public void clearAllTables() {
    super.assertNotMainThread();
    final SupportSQLiteDatabase _db = super.getOpenHelper().getWritableDatabase();
    try {
      super.beginTransaction();
      _db.execSQL("DELETE FROM `teachers`");
      _db.execSQL("DELETE FROM `students`");
      _db.execSQL("DELETE FROM `debate_sessions`");
      _db.execSQL("DELETE FROM `speech_recordings`");
      super.setTransactionSuccessful();
    } finally {
      super.endTransaction();
      _db.query("PRAGMA wal_checkpoint(FULL)").close();
      if (!_db.inTransaction()) {
        _db.execSQL("VACUUM");
      }
    }
  }

  @Override
  @NonNull
  protected Map<Class<?>, List<Class<?>>> getRequiredTypeConverters() {
    final HashMap<Class<?>, List<Class<?>>> _typeConvertersMap = new HashMap<Class<?>, List<Class<?>>>();
    _typeConvertersMap.put(DebateFeedbackDao.class, DebateFeedbackDao_Impl.getRequiredConverters());
    return _typeConvertersMap;
  }

  @Override
  @NonNull
  public Set<Class<? extends AutoMigrationSpec>> getRequiredAutoMigrationSpecs() {
    final HashSet<Class<? extends AutoMigrationSpec>> _autoMigrationSpecsSet = new HashSet<Class<? extends AutoMigrationSpec>>();
    return _autoMigrationSpecsSet;
  }

  @Override
  @NonNull
  public List<Migration> getAutoMigrations(
      @NonNull final Map<Class<? extends AutoMigrationSpec>, AutoMigrationSpec> autoMigrationSpecs) {
    final List<Migration> _autoMigrations = new ArrayList<Migration>();
    return _autoMigrations;
  }

  @Override
  public DebateFeedbackDao debateDao() {
    if (_debateFeedbackDao != null) {
      return _debateFeedbackDao;
    } else {
      synchronized(this) {
        if(_debateFeedbackDao == null) {
          _debateFeedbackDao = new DebateFeedbackDao_Impl(this);
        }
        return _debateFeedbackDao;
      }
    }
  }
}
