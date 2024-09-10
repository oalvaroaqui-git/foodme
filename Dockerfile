# Use uma imagem base do Node.js com o LTS (Long Term Support)
FROM node:18-alpine

# Definir o diretório de trabalho dentro do container
WORKDIR /usr/src/app

# Copiar o package.json e package-lock.json para instalar as dependências
COPY package*.json ./

# Instalar as dependências
RUN npm install

# Copiar o restante do código da aplicação para o container
COPY . .

# Expor a porta que a aplicação escuta (ajuste se necessário)
EXPOSE 3000

# Comando para iniciar a aplicação
CMD [ "node", "server/start.js" ]