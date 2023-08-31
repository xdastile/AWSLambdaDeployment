# Define custom function directory
ARG FUNCTION_DIR="/function"

FROM python:3.8 as build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

RUN mkdir -p ${FUNCTION_DIR}
COPY .dvc ${FUNCTION_DIR}
COPY models.dvc ${FUNCTION_DIR}
COPY requirements.txt ${FUNCTION_DIR}
COPY lambda_handler.py ${FUNCTION_DIR}

WORKDIR ${FUNCTION_DIR}

RUN pip install -r requirements.txt --target ${FUNCTION_DIR}

# Install the function's dependencies
RUN pip install \
    --target ${FUNCTION_DIR} \
        awslambdaric

FROM python:3.8

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

RUN pip install awscli
RUN pip install dvc
RUN pip install "dvc[s3]"

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

RUN dvc init --no-scm -f
RUN dvc remote add -d model-store s3://models-dvc-xd/

# pulling the trained model
RUN dvc pull

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "lambda_handler.lambda_handler" ]