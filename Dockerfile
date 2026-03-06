# Tomcat 10 を使って Java 17 を動かす設定
FROM tomcat:10.1-jdk17-openjdk-slim

# 古いデフォルトページを削除
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# index.jsp などがある場所をコピー（フォルダ名はあなたの構成に合わせて調整）
COPY src/main/webapp /usr/local/tomcat/webapps/ROOT

# コンパイル済みのJavaプログラム(ScoreServletなど)をコピー
COPY build/classes /usr/local/tomcat/webapps/ROOT/WEB-INF/classes

# ライブラリ(Gsonなど)をコピー
COPY src/main/webapp/WEB-INF/lib /usr/local/tomcat/webapps/ROOT/WEB-INF/lib

EXPOSE 8080
CMD ["catalina.sh", "run"]
