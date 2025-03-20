import 'package:google_generative_ai/google_generative_ai.dart';
import 'tomato.dart' as tomato;


Schema schema=Schema.object(properties: 
{
  '작물명': Schema.string(),
  '조사자': Schema.string(),
  '농가명': Schema.string(),
  '지난_조사일': Schema.string(description: "지난 조사일"),
  '조사일': Schema.string(),
  'data': Schema.object(
    properties: {
      '토마토':tomato.schema
    }
  ),
});