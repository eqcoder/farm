import 'package:google_generative_ai/google_generative_ai.dart';

final schema = Schema.array(
    description: 'List of recipes',
    items: Schema.object(properties: {
      'recipeName':
          Schema.string(description: 'Name of the recipe.', nullable: false)
    }, requiredProperties: [
      'recipeName'
    ]));
