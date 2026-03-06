<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html>
<head>
    <title>TETRIS PRO - ULTIMATE</title>
    <style>
        body { background: #050505; color: #eee; font-family: 'Segoe UI', sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; overflow: hidden; }
        .container { display: flex; gap: 20px; background: #111; padding: 20px; border-radius: 12px; border: 1px solid #333; }
        canvas { background: #000; border: 2px solid #444; }
        .side { width: 170px; display: flex; flex-direction: column; gap: 10px; }
        .ui-box { background: #000; padding: 10px; border: 1px solid #222; text-align: center; border-radius: 6px; }
        .label { font-size: 11px; color: #888; margin-bottom: 4px; text-transform: uppercase; }
        .val { font-size: 24px; color: #00d4ff; font-weight: bold; font-family: monospace; }
        #gameover { position: absolute; background: rgba(0,0,0,0.9); width: 300px; height: 600px; display: none; flex-direction: column; align-items: center; justify-content: center; z-index: 9999; }
        button { background: #222; color: #00d4ff; border: 1px solid #00d4ff; padding: 10px; cursor: pointer; border-radius: 4px; font-weight: bold; }
        button:hover { background: #00d4ff; color: #000; }
        #rankList { text-align: left; font-size: 13px; color: #ccc; padding: 0; list-style: none; margin-top: 5px; max-height: 200px; overflow-y: auto; }
        #rankList li { border-bottom: 1px solid #222; padding: 5px 0; display: flex; justify-content: space-between; }
    </style>
</head>
<body>
    <div class="container">
        <div class="side">
            <div class="ui-box"><div class="label">HOLD</div><canvas id="holdCanvas" width="100" height="100"></canvas></div>
            <div class="ui-box"><div class="label">SCORE</div><div id="scoreDisplay" class="val">0</div></div>
            <div class="ui-box"><div class="label">LEVEL</div><div id="levelDisplay" class="val">1</div></div>
        </div>
        <div style="position: relative;">
            <div id="gameover"><h1>GAME OVER</h1><button onclick="location.reload()">RETRY</button></div>
            <canvas id="gameCanvas" width="300" height="600"></canvas>
        </div>
        <div class="side">
            <div class="ui-box"><div class="label">NEXT</div><canvas id="nextCanvas" width="100" height="100"></canvas></div>
            <div class="ui-box"><div class="label">RANKING</div><ul id="rankList"></ul></div>
            <button onclick="saveScore()">SAVE SCORE</button>
        </div>
    </div>

    <script>
        const canvas = document.getElementById('gameCanvas'), ctx = canvas.getContext('2d');
        const nextCtx = document.getElementById('nextCanvas').getContext('2d'), holdCtx = document.getElementById('holdCanvas').getContext('2d');
        const COLORS = [null, "#00f0f0", "#f0f000", "#d020ff", "#00f000", "#f00000", "#0044ff", "#f0a000"];
        const KICKS = [[0,0], [-1,0], [1,0], [0,-1], [-1,-1], [1,-1]];
        const SHAPES = [null, 
            [[0,0,0,0],[1,1,1,1],[0,0,0,0],[0,0,0,0]], [[2,2],[2,2]], [[0,3,0],[3,3,3],[0,0,0]], 
            [[0,4,4],[4,4,0],[0,0,0]], [[5,5,0],[0,5,5],[0,0,0]], [[6,0,0],[6,6,6],[0,0,0]], [[0,0,7],[7,7,7],[0,0,0]]
        ];

        let board = Array.from({length: 20}, () => Array(10).fill(0));
        let current = null, nextPiece = null, hold = null;
        let px = 3, py = 0, score = 0, level = 1, canHold = true, isGameOver = false, isProcessing = false;
        let landTime = 0, lastDropTime = 0;
        const LOCK_DELAY = 1500;
        const keys = {};
        let moveState = { dir: 0, lastMove: 0, startTime: 0 };

        async function init() {
            loadRank();
            await fetch('ScoreServlet?type=reset');
            nextPiece = await fetchNext();
            spawn();
            lastDropTime = Date.now();
            requestAnimationFrame(gameLoop);
        }

        async function fetchNext() {
            const res = await fetch('ScoreServlet?type=next');
            return await res.json();
        }

        function gameLoop() {
            const now = Date.now();
            if (!isGameOver && !isProcessing && current) {
                handleInput(now);
                const dropInterval = Math.max(100, 800 - (level - 1) * 70);
                if (now - lastDropTime > (keys[40] ? 40 : dropInterval)) { 
                    if (!collide(px, py + 1)) { py++; landTime = 0; }
                    lastDropTime = now;
                }
                if (collide(px, py + 1)) {
                    if (landTime === 0) landTime = now;
                    if (now - landTime > LOCK_DELAY) { fix(); }
                }
            }
            draw();
            requestAnimationFrame(gameLoop);
        }

        function handleInput(now) {
            let dir = 0;
            if (keys[37]) dir = -1;
            if (keys[39]) dir = 1;
            if (dir !== 0) {
                if (moveState.dir !== dir) {
                    if (!collide(px + dir, py)) px += dir;
                    moveState.dir = dir; moveState.startTime = now; moveState.lastMove = now;
                } else if (now - moveState.startTime > 120 && now - moveState.lastMove > 25) {
                    if (!collide(px + dir, py)) px += dir;
                    moveState.lastMove = now;
                }
            } else { moveState.dir = 0; }
        }

        async function spawn() {
            if (isGameOver) return;
            current = nextPiece;
            px = 3; py = 0; canHold = true; landTime = 0;
            if (collide(px, py)) { 
                isGameOver = true; 
                document.getElementById('gameover').style.display = 'flex'; 
                return; 
            }
            nextPiece = await fetchNext();
            drawSide();
        }

        async function fix() {
            if (isProcessing || !current) return;
            isProcessing = true;
            const shapeStr = JSON.stringify(current);
            const res = await fetch('ScoreServlet?type=fix&px='+px+'&py='+py+'&shape='+encodeURIComponent(shapeStr));
            const data = await res.json();
            score += (data.addedScore || 0) + 10;
            level = Math.floor(score / 1000) + 1;
            document.getElementById('scoreDisplay').innerText = score;
            document.getElementById('levelDisplay').innerText = level;
            const bRes = await fetch('ScoreServlet?type=board');
            board = await bRes.json();
            isProcessing = false;
            spawn();
        }

        function collide(nx, ny, p = current) {
            return p.some((row, y) => row.some((v, x) => {
                if(!v) return false;
                let tx = nx+x, ty = ny+y;
                return tx < 0 || tx >= 10 || ty >= 20 || (ty >= 0 && board[ty][tx]);
            }));
        }

        function rotate(dir) {
            const nextS = current[0].map((_, i) => current.map(row => row[i]));
            if (dir === 1) nextS.forEach(row => row.reverse()); else nextS.reverse();
            for (let [kx, ky] of KICKS) {
                if (!collide(px + kx, py + ky, nextS)) { px += kx; py += ky; current = nextS; return; }
            }
        }

        window.addEventListener("keydown", e => {
            keys[e.keyCode] = true;
            if (isGameOver || isProcessing || !current) return;
            if (e.keyCode === 90) rotate(-1);
            if (e.keyCode === 88 || e.keyCode === 38) rotate(1);
            if (e.keyCode === 32) { e.preventDefault(); while(!collide(px, py + 1)) py++; fix(); }
            if (e.keyCode === 67 && canHold) { 
                const id = current.flat().find(v => v > 0);
                const fresh = SHAPES[id];
                if (!hold) { hold = fresh; spawn(); } 
                else { const t = hold; hold = fresh; current = t; px = 3; py = 0; }
                canHold = false; drawSide();
            }
        });
        window.addEventListener("keyup", e => { keys[e.keyCode] = false; });

        function draw() {
            ctx.clearRect(0, 0, 300, 600);
            board.forEach((r, y) => r.forEach((v, x) => { if(v) drawBlock(ctx, x, y, 30, COLORS[v]); }));
            if(current) {
                let gy = py; while(!collide(px, gy + 1)) gy++;
                drawShape(ctx, current, px, gy, 30, true);
                drawShape(ctx, current, px, py, 30);
            }
        }

        function drawSide() {
            [nextCtx, holdCtx].forEach(c => c.clearRect(0,0,100,100));
            if(nextPiece) drawShape(nextCtx, nextPiece, 1, 1, 20);
            if(hold) drawShape(holdCtx, hold, 1, 1, 20);
        }

        function drawShape(c, s, ox, oy, size, ghost = false) {
            const id = s.flat().find(v => v > 0);
            const color = ghost ? "rgba(255,255,255,0.15)" : COLORS[id];
            s.forEach((row, y) => row.forEach((v, x) => { if(v) drawBlock(c, ox+x, oy+y, size, color); }));
        }

        function drawBlock(c, x, y, size, color) {
            c.fillStyle = color;
            c.fillRect(x*size+1, y*size+1, size-2, size-2);
        }

        function loadRank() {
            fetch('ScoreServlet?type=rank').then(res => res.text())
            .then(html => { document.getElementById('rankList').innerHTML = html; });
        }

        function saveScore() {
            const name = prompt("Name:");
            if(name) {
                const p = new URLSearchParams(); p.append('name', name); p.append('score', score);
                fetch('ScoreServlet', { method:'POST', body: p }).then(() => { loadRank(); alert("SAVED!"); });
            }
        }
        window.onload = init;
    </script>
</body>
</html>