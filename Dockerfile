FROM node:18

WORKDIR /app

COPY api/package*.json ./
RUN npm install

COPY api .

RUN npm run build

EXPOSE 4000

CMD ["npm", "start"]
