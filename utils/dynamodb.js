const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { 
  DynamoDBDocumentClient, 
  ScanCommand, 
  GetCommand, 
  PutCommand, 
  BatchWriteCommand,
  QueryCommand,
  DeleteCommand
} = require('@aws-sdk/lib-dynamodb');

// Configure AWS SDK
const region = process.env.AWS_REGION || 'ap-southeast-1';
const client = new DynamoDBClient({ region });
const dynamoDB = DynamoDBDocumentClient.from(client);

// Table names from environment variables
const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE || 'shopmate-products-dev';
const ORDERS_TABLE = process.env.ORDERS_TABLE || 'shopmate-orders-dev';
const CARTS_TABLE = process.env.CARTS_TABLE || 'shopmate-carts-dev';

// Helper functions for common operations
const scan = async (params) => {
  // If params is just a table name string, convert to proper format
  if (typeof params === 'string') {
    params = { TableName: params };
  }
  
  // Add resource limits to prevent excessive data retrieval
  if (!params.Limit) {
    params.Limit = 1000; // Maximum 1000 items per scan
  }
  
  const command = new ScanCommand(params);
  const response = await dynamoDB.send(command);
  return response.Items || [];
};

const query = async (params) => {
  const command = new QueryCommand(params);
  const response = await dynamoDB.send(command);
  return response.Items || [];
};

const get = async (tableName, key) => {
  const command = new GetCommand({
    TableName: tableName,
    Key: key
  });
  const response = await dynamoDB.send(command);
  return response.Item;
};

const put = async (tableName, item) => {
  const command = new PutCommand({
    TableName: tableName,
    Item: item
  });
  return dynamoDB.send(command);
};

const deleteItem = async (tableName, key) => {
  const command = new DeleteCommand({
    TableName: tableName,
    Key: key
  });
  return dynamoDB.send(command);
};

const batchWrite = async (tableName, items) => {
  // Limit batch size to prevent resource exhaustion
  if (items.length > 25) {
    throw new Error('Batch write limited to 25 items maximum');
  }
  
  const putRequests = items.map(item => ({
    PutRequest: { Item: item }
  }));
  
  const command = new BatchWriteCommand({
    RequestItems: {
      [tableName]: putRequests
    }
  });
  
  return dynamoDB.send(command);
};

module.exports = {
  dynamoDB,
  PRODUCTS_TABLE,
  ORDERS_TABLE,
  CARTS_TABLE,
  scan,
  query,
  get,
  put,
  deleteItem,
  batchWrite
};