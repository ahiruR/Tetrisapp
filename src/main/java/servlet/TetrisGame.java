package servlet;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class TetrisGame {
    private int[][] board = new int[20][10];
    private List<Integer> bag = new ArrayList<>();
    
    // 標準的なテトリミノの形状定義
    private static final int[][][] SHAPES = {
        {}, 
        {{0,0,0,0},{1,1,1,1},{0,0,0,0},{0,0,0,0}}, // I
        {{2,2},{2,2}},                               // O
        {{0,3,0},{3,3,3},{0,0,0}},                   // T
        {{0,4,4},{4,4,0},{0,0,0}},                   // S
        {{5,5,0},{0,5,5},{0,0,0}},                   // Z
        {{6,0,0},{6,6,6},{0,0,0}},                   // J
        {{0,0,7},{7,7,7},{0,0,0}}                    // L
    };

    // 7種類1セットの袋からランダムに取り出す（7-Bagシステム）
    public synchronized int[][] getNextPiece() {
        if (bag.isEmpty()) {
            for (int i = 1; i <= 7; i++) bag.add(i);
            Collections.shuffle(bag);
        }
        return SHAPES[bag.remove(0)];
    }

    public synchronized void resetGame() {
        board = new int[20][10];
        bag.clear();
    }

    public synchronized int[][] getBoard() {
        return board;
    }

    // ミノの固定とライン消去の処理
    public synchronized int fixAndScore(int[][] shape, int px, int py) {
        for (int y = 0; y < shape.length; y++) {
            for (int x = 0; x < shape[y].length; x++) {
                if (shape[y][x] > 0) {
                    int ty = py + y, tx = px + x;
                    if (ty >= 0 && ty < 20 && tx >= 0 && tx < 10) {
                        board[ty][tx] = shape[y][x];
                    }
                }
            }
        }
        int lines = 0;
        for (int y = 19; y >= 0; y--) {
            boolean full = true;
            for (int x = 0; x < 10; x++) if (board[y][x] == 0) { full = false; break; }
            if (full) {
                lines++;
                for (int ty = y; ty > 0; ty--) board[ty] = board[ty - 1].clone();
                board[0] = new int[10];
                y++;
            }
        }
        // 消去ライン数に応じたスコア加算
        return (lines == 1) ? 100 : (lines == 2) ? 300 : (lines == 3) ? 500 : (lines == 4) ? 800 : 0;
    }
}