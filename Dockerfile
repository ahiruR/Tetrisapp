# Tomcat 10 を準備
FROM tomcat:10.1-jdk17-openjdk-slim

# デフォルトのROOTを削除
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# フォルダ構造を維持してコピー
# index.jspなどがある場所
COPY src/main/webapp /usr/local/tomcat/webapps/ROOT

# Javaのプログラム(classファイル)をコピー
# パッケージ名(servlet)のフォルダごとコピーします
COPY build/classes/servlet /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/servlet

# ライブラリ(Gsonなど)をコピー
COPY src/main/webapp/WEB-INF/lib /usr/local/tomcat/webapps/ROOT/WEB-INF/lib

EXPOSE 8080
CMD ["catalina.sh", "run"]
