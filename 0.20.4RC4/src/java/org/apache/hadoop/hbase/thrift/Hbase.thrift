/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ----------------------------------------------------------------
// HBase.thrift -
//
// This is a Thrift interface definition file for the Hbase service.
// Target language libraries for C++, Java, Ruby, PHP, (and more) are
// generated by running this file through the Thrift compiler with the
// appropriate flags.  The Thrift compiler binary and runtime
// libraries for various languages is currently available from
// Facebook (http://developers.facebook.com/thrift/).  The intent is
// for the Thrift project to migrate to Apache Incubator.
//
// See the package.html file for information on the version of Thrift
// used to generate the *.java files checked into the Hbase project.
// ----------------------------------------------------------------

namespace java org.apache.hadoop.hbase.thrift.generated
namespace cpp  apache.hadoop.hbase.thrift
namespace rb Apache.Hadoop.Hbase.Thrift
namespace py hbase
namespace perl Hbase

// note: other language namespaces tbd...

//
// Types
//

// NOTE: all variables with the Text type are assumed to be correctly
// formatted UTF-8 strings.  This is a programming language and locale
// dependent property that the client application is repsonsible for
// maintaining.  If strings with an invalid encoding are sent, an
// IOError will be thrown.

typedef binary Text
typedef binary Bytes
typedef i32    ScannerID

/**
 * TCell - Used to transport a cell value (byte[]) and the timestamp it was 
 * stored with together as a result for get and getRow methods. This promotes
 * the timestamp of a cell to a first-class value, making it easy to take 
 * note of temporal data. Cell is used all the way from HStore up to HTable.
 */
struct TCell{
  1:Bytes value,
  2:i64 timestamp
}

/**
 * An HColumnDescriptor contains information about a column family
 * such as the number of versions, compression settings, etc. It is
 * used as input when creating a table or adding a column.
 */
struct ColumnDescriptor {
  1:Text name,
  2:i32 maxVersions = 3,
  3:string compression = "NONE",
  4:bool inMemory = 0,
  5:string bloomFilterType = "NONE",
  6:i32 bloomFilterVectorSize = 0,
  7:i32 bloomFilterNbHashes = 0,
  8:bool blockCacheEnabled = 0,
  9:i32 timeToLive = -1
}

/**
 * A TRegionInfo contains information about an HTable region.
 */
struct TRegionInfo {
  1:Text startKey,
  2:Text endKey,
  3:i64 id,
  4:Text name,
  5:byte version 
}

/**
 * A Mutation object is used to either update or delete a column-value.
 */
struct Mutation {
  1:bool isDelete = 0,
  2:Text column,
  3:Text value
}


/**
 * A BatchMutation object is used to apply a number of Mutations to a single row.
 */
struct BatchMutation {
  1:Text row,
  2:list<Mutation> mutations
}


/**
 * Holds row name and then a map of columns to cells. 
 */
struct TRowResult {
  1:Text row,
  2:map<Text, TCell> columns
}

//
// Exceptions
//
/**
 * An IOError exception signals that an error occurred communicating
 * to the Hbase master or an Hbase region server.  Also used to return
 * more general Hbase error conditions.
 */
exception IOError {
  1:string message
}

/**
 * An IllegalArgument exception indicates an illegal or invalid
 * argument was passed into a procedure.
 */
exception IllegalArgument {
  1:string message
}

/**
 * An AlreadyExists exceptions signals that a table with the specified
 * name already exists
 */
exception AlreadyExists {
  1:string message
}

//
// Service 
//

service Hbase {
  /**
   * Brings a table on-line (enables it)
   * @param tableName name of the table
   */
  void enableTable(1:Bytes tableName)
    throws (1:IOError io)
    
  /**
   * Disables a table (takes it off-line) If it is being served, the master
   * will tell the servers to stop serving it.
   * @param tableName name of the table
   */
  void disableTable(1:Bytes tableName)
    throws (1:IOError io)

  /**
   * @param tableName name of table to check
   * @return true if table is on-line
   */
  bool isTableEnabled(1:Bytes tableName)
    throws (1:IOError io)
    
  void compact(1:Bytes tableNameOrRegionName)
    throws (1:IOError io)
  
  void majorCompact(1:Bytes tableNameOrRegionName)
    throws (1:IOError io)
    
  /**
   * List all the userspace tables.
   * @return - returns a list of names
   */
  list<Text> getTableNames()
    throws (1:IOError io)

  /**
   * List all the column families assoicated with a table.
   * @param tableName table name
   * @return list of column family descriptors
   */
  map<Text,ColumnDescriptor> getColumnDescriptors (1:Text tableName)
    throws (1:IOError io)

  /**
   * List the regions associated with a table.
   * @param tableName table name
   * @return list of region descriptors
   */
  list<TRegionInfo> getTableRegions(1:Text tableName) 
    throws (1:IOError io)

  /**
   * Create a table with the specified column families.  The name
   * field for each ColumnDescriptor must be set and must end in a
   * colon (:).  All other fields are optional and will get default
   * values if not explicitly specified.
   *
   * @param tableName name of table to create
   * @param columnFamilies list of column family descriptors
   *
   * @throws IllegalArgument if an input parameter is invalid
   * @throws AlreadyExists if the table name already exists
   */ 
  void createTable(1:Text tableName, 2:list<ColumnDescriptor> columnFamilies)
    throws (1:IOError io, 2:IllegalArgument ia, 3:AlreadyExists exist)

  /**
   * Deletes a table
   * @param tableName name of table to delete
   * @throws IOError if table doesn't exist on server or there was some other
   * problem
   */
  void deleteTable(1:Text tableName)
    throws (1:IOError io)

  /** 
   * Get a single TCell for the specified table, row, and column at the
   * latest timestamp. Returns an empty list if no such value exists.
   *
   * @param tableName name of table
   * @param row row key
   * @param column column name
   * @return value for specified row/column
   */
  list<TCell> get(1:Text tableName, 2:Text row, 3:Text column) 
    throws (1:IOError io)

  /** 
   * Get the specified number of versions for the specified table,
   * row, and column.
   *
   * @param tableName name of table
   * @param row row key
   * @param column column name
   * @param numVersions number of versions to retrieve
   * @return list of cells for specified row/column
   */
  list<TCell> getVer(1:Text tableName, 2:Text row, 3:Text column,
      4:i32 numVersions) 
    throws (1:IOError io)

  /** 
   * Get the specified number of versions for the specified table,
   * row, and column.  Only versions less than or equal to the specified
   * timestamp will be returned.
   *
   * @param tableName name of table
   * @param row row key
   * @param column column name
   * @param timestamp timestamp
   * @param numVersions number of versions to retrieve
   * @return list of cells for specified row/column
   */
  list<TCell> getVerTs(1:Text tableName, 2:Text row, 3:Text column, 
      4:i64 timestamp,  5:i32 numVersions)
    throws (1:IOError io)

  /** 
   * Get all the data for the specified table and row at the latest
   * timestamp. Returns an empty list if the row does not exist.
   * 
   * @param tableName name of table
   * @param row row key
   * @return TRowResult containing the row and map of columns to TCells
   */
  list<TRowResult> getRow(1:Text tableName, 2:Text row)
    throws (1:IOError io)

  /** 
   * Get the specified columns for the specified table and row at the latest
   * timestamp. Returns an empty list if the row does not exist.
   * 
   * @param tableName name of table
   * @param row row key
   * @param columns List of columns to return, null for all columns
   * @return TRowResult containing the row and map of columns to TCells
   */
  list<TRowResult> getRowWithColumns(1:Text tableName, 2:Text row,
      3:list<Text> columns)
    throws (1:IOError io)

  /** 
   * Get all the data for the specified table and row at the specified
   * timestamp. Returns an empty list if the row does not exist.
   * 
   * @param tableName of table
   * @param row row key
   * @param timestamp timestamp
   * @return TRowResult containing the row and map of columns to TCells
   */
  list<TRowResult> getRowTs(1:Text tableName, 2:Text row, 3:i64 timestamp)
    throws (1:IOError io)
    
  /** 
   * Get the specified columns for the specified table and row at the specified
   * timestamp. Returns an empty list if the row does not exist.
   * 
   * @param tableName name of table
   * @param row row key
   * @param columns List of columns to return, null for all columns
   * @return TRowResult containing the row and map of columns to TCells
   */
  list<TRowResult> getRowWithColumnsTs(1:Text tableName, 2:Text row,
      3:list<Text> columns, 4:i64 timestamp)
    throws (1:IOError io)

  /** 
   * Apply a series of mutations (updates/deletes) to a row in a
   * single transaction.  If an exception is thrown, then the
   * transaction is aborted.  Default current timestamp is used, and
   * all entries will have an identical timestamp.
   *
   * @param tableName name of table
   * @param row row key
   * @param mutations list of mutation commands
   */
  void mutateRow(1:Text tableName, 2:Text row, 3:list<Mutation> mutations)
    throws (1:IOError io, 2:IllegalArgument ia)

  /** 
   * Apply a series of mutations (updates/deletes) to a row in a
   * single transaction.  If an exception is thrown, then the
   * transaction is aborted.  The specified timestamp is used, and
   * all entries will have an identical timestamp.
   *
   * @param tableName name of table
   * @param row row key
   * @param mutations list of mutation commands
   * @param timestamp timestamp
   */
  void mutateRowTs(1:Text tableName, 2:Text row, 3:list<Mutation> mutations, 4:i64 timestamp)
    throws (1:IOError io, 2:IllegalArgument ia)

  /** 
   * Apply a series of batches (each a series of mutations on a single row)
   * in a single transaction.  If an exception is thrown, then the
   * transaction is aborted.  Default current timestamp is used, and
   * all entries will have an identical timestamp.
   *
   * @param tableName name of table
   * @param rowBatches list of row batches
   */
  void mutateRows(1:Text tableName, 2:list<BatchMutation> rowBatches)
    throws (1:IOError io, 2:IllegalArgument ia)

  /** 
   * Apply a series of batches (each a series of mutations on a single row)
   * in a single transaction.  If an exception is thrown, then the
   * transaction is aborted.  The specified timestamp is used, and
   * all entries will have an identical timestamp.
   *
   * @param tableName name of table
   * @param rowBatches list of row batches
   * @param timestamp timestamp
   */
  void mutateRowsTs(1:Text tableName, 2:list<BatchMutation> rowBatches, 3:i64 timestamp)
    throws (1:IOError io, 2:IllegalArgument ia)

  /**
   * Atomically increment the column value specified.  Returns the next value post increment.
   * @param tableName name of table
   * @param row row to increment
   * @param column name of column
   * @param value amount to increment by
   */
  i64 atomicIncrement(1:Text tableName, 2:Text row, 3:Text column, 4:i64 value)
    throws (1:IOError io, 2:IllegalArgument ia)
    
  /** 
   * Delete all cells that match the passed row and column.
   *
   * @param tableName name of table
   * @param row Row to update
   * @param column name of column whose value is to be deleted
   */
  void deleteAll(1:Text tableName, 2:Text row, 3:Text column)
    throws (1:IOError io)

  /** 
   * Delete all cells that match the passed row and column and whose
   * timestamp is equal-to or older than the passed timestamp.
   *
   * @param tableName name of table
   * @param row Row to update
   * @param column name of column whose value is to be deleted
   * @param timestamp timestamp
   */
  void deleteAllTs(1:Text tableName, 2:Text row, 3:Text column, 4:i64 timestamp)
    throws (1:IOError io)

  /**
   * Completely delete the row's cells.
   *
   * @param tableName name of table
   * @param row key of the row to be completely deleted.
   */
  void deleteAllRow(1:Text tableName, 2:Text row)
    throws (1:IOError io)

  /**
   * Completely delete the row's cells marked with a timestamp
   * equal-to or older than the passed timestamp.
   *
   * @param tableName name of table
   * @param row key of the row to be completely deleted.
   * @param timestamp timestamp
   */
  void deleteAllRowTs(1:Text tableName, 2:Text row, 3:i64 timestamp)
    throws (1:IOError io)

  /** 
   * Get a scanner on the current table starting at the specified row and
   * ending at the last row in the table.  Return the specified columns.
   *
   * @param columns columns to scan. If column name is a column family, all
   * columns of the specified column family are returned.  Its also possible
   * to pass a regex in the column qualifier.
   * @param tableName name of table
   * @param startRow starting row in table to scan.  send "" (empty string) to
   *                 start at the first row.
   *
   * @return scanner id to be used with other scanner procedures
   */
  ScannerID scannerOpen(1:Text tableName, 
                        2:Text startRow,
                        3:list<Text> columns)
    throws (1:IOError io)

  /** 
   * Get a scanner on the current table starting and stopping at the
   * specified rows.  ending at the last row in the table.  Return the
   * specified columns.
   *
   * @param columns columns to scan. If column name is a column family, all
   * columns of the specified column family are returned.  Its also possible
   * to pass a regex in the column qualifier.
   * @param tableName name of table
   * @param startRow starting row in table to scan.  send "" (empty string) to
   *                 start at the first row.
   * @param stopRow row to stop scanning on.  This row is *not* included in the
   *                scanner's results
   *
   * @return scanner id to be used with other scanner procedures
   */
  ScannerID scannerOpenWithStop(1:Text tableName, 
                                2:Text startRow,
                                3:Text stopRow, 
                                4:list<Text> columns)
    throws (1:IOError io)

  /**
   * Open a scanner for a given prefix.  That is all rows will have the specified
   * prefix. No other rows will be returned.
   *
   * @param tableName name of table
   * @param startAndPrefix the prefix (and thus start row) of the keys you want
   * @param columns the columns you want returned
   * @return scanner id to use with other scanner calls
   */
  ScannerID scannerOpenWithPrefix(1:Text tableName,
                                  2:Text startAndPrefix,
                                  3:list<Text> columns)
    throws (1:IOError io)

  /** 
   * Get a scanner on the current table starting at the specified row and
   * ending at the last row in the table.  Return the specified columns.
   * Only values with the specified timestamp are returned.
   *
   * @param columns columns to scan. If column name is a column family, all
   * columns of the specified column family are returned.  Its also possible
   * to pass a regex in the column qualifier.
   * @param tableName name of table
   * @param startRow starting row in table to scan.  send "" (empty string) to
   *                 start at the first row.
   * @param timestamp timestamp
   *
   * @return scanner id to be used with other scanner procedures
   */
  ScannerID scannerOpenTs(1:Text tableName, 
                          2:Text startRow,
                          3:list<Text> columns,
                          4:i64 timestamp)
    throws (1:IOError io)

  /** 
   * Get a scanner on the current table starting and stopping at the
   * specified rows.  ending at the last row in the table.  Return the
   * specified columns.  Only values with the specified timestamp are
   * returned.
   *
   * @param columns columns to scan. If column name is a column family, all
   * columns of the specified column family are returned.  Its also possible
   * to pass a regex in the column qualifier.
   * @param tableName name of table
   * @param startRow starting row in table to scan.  send "" (empty string) to
   *                 start at the first row.
   * @param stopRow row to stop scanning on.  This row is *not* included
   *                in the scanner's results
   * @param timestamp timestamp
   *
   * @return scanner id to be used with other scanner procedures
   */
  ScannerID scannerOpenWithStopTs(1:Text tableName, 
                                  2:Text startRow,
                                  3:Text stopRow, 
                                  4:list<Text> columns,
                                  5:i64 timestamp)
    throws (1:IOError io)

  /**
   * Returns the scanner's current row value and advances to the next
   * row in the table.  When there are no more rows in the table, or a key
   * greater-than-or-equal-to the scanner's specified stopRow is reached,
   * an empty list is returned.
   *
   * @param id id of a scanner returned by scannerOpen
   * @return a TRowResult containing the current row and a map of the columns to TCells.
   * @throws IllegalArgument if ScannerID is invalid
   * @throws NotFound when the scanner reaches the end
   */
  list<TRowResult> scannerGet(1:ScannerID id)
    throws (1:IOError io, 2:IllegalArgument ia)

  /**
   * Returns, starting at the scanner's current row value nbRows worth of
   * rows and advances to the next row in the table.  When there are no more 
   * rows in the table, or a key greater-than-or-equal-to the scanner's 
   * specified stopRow is reached,  an empty list is returned.
   *
   * @param id id of a scanner returned by scannerOpen
   * @param nbRows number of results to regturn
   * @return a TRowResult containing the current row and a map of the columns to TCells.
   * @throws IllegalArgument if ScannerID is invalid
   * @throws NotFound when the scanner reaches the end
   */
  list<TRowResult> scannerGetList(1:ScannerID id,2:i32 nbRows)
    throws (1:IOError io, 2:IllegalArgument ia)

  /**
   * Closes the server-state associated with an open scanner.
   *
   * @param id id of a scanner returned by scannerOpen
   * @throws IllegalArgument if ScannerID is invalid
   */
  void scannerClose(1:ScannerID id)
    throws (1:IOError io, 2:IllegalArgument ia)
}
