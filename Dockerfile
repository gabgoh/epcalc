FROM node:13-alpine as builder
# Set directory for all files
WORKDIR /home/node
# Copy over package.json files
COPY package*.json ./
# Install all packages
RUN npm install
# Copy over source code
COPY . .
# Build project
RUN npm run build


# Use nginx:alpine as base image
FROM nginx:alpine
# Copy over built files
COPY --from=builder /home/node/public /usr/share/nginx/html
# Expose port 80 let host handle HTTPS etc
EXPOSE 80
