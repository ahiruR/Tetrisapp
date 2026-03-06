# Tomcat 10（Java 17）を準備
FROM tomcat:10.1-jdk17-openjdk-slim

# もともと入っている不要なファイルを消す
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# index.jsp などがある場所（src/main/webapp）をコピー
COPY src/main/webapp /usr/local/tomcat/webapps/ROOT

# コンパイルされたプログラム（build/classes）を配置場所にコピー
COPY build/classes /usr/local/tomcat/webapps/ROOT/WEB-INF/classes

# ライブラリ（src/main/webapp/WEB-INF/lib）を配置場所にコピー
COPY src/main/webapp/WEB-INF/lib /usr/local/tomcat/webapps/ROOT/WEB-INF/lib

EXPOSE 8080
CMD ["catalina.sh", "run"]
