FROM node:18-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --legacy-peer-deps --omit=dev

COPY . .

EXPOSE 8000

CMD ["npm", "start"] 