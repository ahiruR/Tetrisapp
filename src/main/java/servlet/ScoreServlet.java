package servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import com.google.gson.Gson;

@WebServlet("/ScoreServlet")
public class ScoreServlet extends HttpServlet {
    private static final List<Map<String, Object>> rankings = Collections.synchronizedList(new ArrayList<>());
    private static final Gson gson = new Gson();

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String type = request.getParameter("type");
        HttpSession session = request.getSession();
        
        // セッションごとにゲーム状態を保持
        TetrisGame game = (TetrisGame) session.getAttribute("game");
        if (game == null) {
            game = new TetrisGame();
            session.setAttribute("game", game);
        }

        response.setCharacterEncoding("UTF-8");
        
        if ("next".equals(type)) {
            response.setContentType("application/json");
            response.getWriter().print(gson.toJson(game.getNextPiece()));
        } else if ("board".equals(type)) {
            response.setContentType("application/json");
            response.getWriter().print(gson.toJson(game.getBoard()));
        } else if ("reset".equals(type)) {
            game.resetGame();
            response.getWriter().print("{\"status\":\"ok\"}");
        } else if ("rank".equals(type)) {
            response.setContentType("text/html");
            PrintWriter out = response.getWriter();
            synchronized (rankings) {
                rankings.sort((a, b) -> (int)b.get("score") - (int)a.get("score"));
                for (int i = 0; i < Math.min(rankings.size(), 10); i++) {
                    Map<String, Object> r = rankings.get(i);
                    out.printf("<li><span>%d. %s</span> <span>%d</span></li>", i+1, r.get("name"), r.get("score"));
                }
            }
        } else if ("fix".equals(type)) {
            int px = Integer.parseInt(request.getParameter("px"));
            int py = Integer.parseInt(request.getParameter("py"));
            int[][] shape = gson.fromJson(request.getParameter("shape"), int[][].class);
            int added = game.fixAndScore(shape, px, py);
            response.setContentType("application/json");
            response.getWriter().print("{\"addedScore\":" + added + "}");
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String name = request.getParameter("name");
        String scoreStr = request.getParameter("score");
        if (name != null && scoreStr != null) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("name", name);
            entry.put("score", Integer.parseInt(scoreStr));
            rankings.add(entry);
        }
    }
}