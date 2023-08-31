import pickle
import json
from pydantic import BaseModel
import pandas as pd


# create a class for the model
class Model:
    def __init__(self):
        # Load the trained model from blob storage or local file (model/model.pkl)
        self.model = pickle.load(open('models/model.pkl', 'rb'))

    def predict(self, input_data):
        # Convert the input data to a DataFrame
        input_df = pd.DataFrame([input_data])

        output = self.model.predict_proba(input_df)

        # Return the output
        return output
    
inferencing_instance=Model()

def lambda_handler(event, context):
    try:
        # Parse the JSON data from the request body
        request_body = json.loads(event['body'])
        
        # Call the predict method with the parsed JSON data
        response = inferencing_instance.predict(request_body)
        
        response_list = response.tolist()
        
        return {
            "statusCode": 200,
            "headers": {},
            "body": json.dumps(response_list),
            "isBase64Encoded": False
        }
    except Exception as e:
        # Handle any exceptions that might occur
        return {
            "statusCode": 500,
            "headers": {},
            "body": json.dumps({"error": str(e)})
        }