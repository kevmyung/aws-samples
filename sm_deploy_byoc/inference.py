import logging
import os
import json
import pickle
import traceback
import numpy as np
import pandas as pd
from tensorflow import keras
from keras.utils import pad_sequences
from sklearn import preprocessing
from konlpy.tag import Okt

okt=Okt()

def model_fn(model_dir):
    try:
        model_path = os.path.join(model_dir, 'model.h5')
        model = keras.models.load_model(model_path)

        word_index_path = os.path.join(model_dir, 'word_index.pkl')
        with open(word_index_path, 'rb') as f:
            model.word_index = pickle.load(f)

        label_path = os.path.join(model_dir, 'labels.csv')
        d = pd.read_csv(label_path)
        labels = d['labels']
        le = preprocessing.LabelEncoder()
        le.fit(labels)
        model.classes_ = list(le.classes_)
            
    except Exception as e:
        logging.error(f"Error in model_fn: {e}")
        raise e

    return model

def input_fn(request_body, content_type='application/json'):
    try:
        if content_type == 'application/json':
            data = json.loads(request_body)
            input_data = data['input']
        else:
            raise ValueError(f"Unsupported content type: {content_type}")
    except Exception as e:
        logging.error(f"Error in input_fn: {e}")
        raise e
    return input_data

def predict_fn(input_data, model):
    try:
        word_index = model.word_index
        test = okt.morphs(input_data)
        bag = [word_index.get(y, 1) for y in test]

        maxlen = 70
        tmp1 = pad_sequences([bag], padding='post', truncating='post', maxlen=maxlen)

        prediction = model.predict(tmp1)
        predicted_class_index = np.argmax(prediction, axis=1)[0]
        result = model.classes_[predicted_class_index]
        result_p = np.round(prediction[0][predicted_class_index], 5)
    except Exception as e:
        logging.error(f"Error in predict_fn: {e}")
        raise e

    return (result, result_p)

def output_fn(predictions, content_type='application/json'):
    try:
        if content_type == 'application/json':
            output_data = {'output': np.array(predictions).tolist()}
        else:
            raise ValueError(f"Unsupported content type: {content_type}")
    except Exception as e:
        logging.error(f"Error in output_fn: {traceback.format_exc()}")
        raise e
    return json.dumps(output_data)