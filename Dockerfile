# Tomcat 10（Java 17）を準備
FROM tomcat:10.1-jdk17-openjdk-slim

# もともと入っている不要なファイルを消す
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# index.jsp などがある場所をコピー
# 画像12枚目のアップロード済みパスに基づき設定
COPY src/main/webapp /usr/local/tomcat/webapps/ROOT

# コンパイルされたプログラム（.classファイル）をコピー
COPY build/classes/servlet /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/servlet

# ライブラリ（Gsonなど）をコピー
COPY src/main/webapp/WEB-INF/lib /usr/local/tomcat/webapps/ROOT/WEB-INF/lib

EXPOSE 8080
CMD ["catalina.sh", "run"]
