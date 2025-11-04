const String baseHost = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://165.22.55.126',
);

const String apiPath = "/api";
const String wsPath = "/ws";
const String baseUrl = '$baseHost$apiPath';
const String wsUrl = '$baseHost$wsPath';
