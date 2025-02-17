FROM node:16.13.2-alpine AS BUILD_IMAGE

ARG TARGETPLATFORM
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}

# Install additional tools needed on arm64 and armv7
RUN \
  case "${TARGETPLATFORM}" in \
  'linux/arm64') apk add --no-cache python3 make g++ ;; \
  'linux/arm/v7') apk add --no-cache python3 make g++ ;; \
  esac

# Create and set the working directory
WORKDIR /app

# Install app dependencies
COPY package.json yarn.lock ./
RUN yarn install

# Copy over all project files and folders to the working directory
COPY . ./

# Build initial app for production
RUN yarn build

# Build the final image
FROM nginx:1.21

# Copy built application from build phase
COPY --from=BUILD_IMAGE /app/dist /usr/share/nginx/html
COPY ./nginx.conf  /usr/share/default.conf

CMD ["/bin/sh", "-c", "envsubst < /usr/share/default.conf > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]

#CMD "envsubst < /tmp/default.conf > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
