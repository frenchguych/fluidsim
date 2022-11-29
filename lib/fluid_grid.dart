class FluidGrid {
  FluidGrid(this.size, this.diff, this.visc)
      : s = List.filled(size * size, 0),
        density = List.filled(size * size, 0),
        vx = List.filled(size * size, 0),
        vy = List.filled(size * size, 0),
        vx0 = List.filled(size * size, 0),
        vy0 = List.filled(size * size, 0);

  int size;
  double diff;
  double visc;

  List<double> s;
  List<double> density;
  List<double> vx;
  List<double> vy;
  List<double> vx0;
  List<double> vy0;

  int ix(int x, int y) {
    return x + (y * size);
  }

  void addDensity(int x, int y, double amount) {
    density[ix(x, y)] += amount;
  }

  void addVelocity(int x, int y, double amountX, double amountY) {
    final index = ix(x, y);
    vx[index] += amountX;
    vy[index] += amountY;
  }

  void step(double dt) {
    for (var j = 0; j < size; j++) {
      for (var i = 0; i < size; i++) {
        density[ix(i, j)] *= .999;
      }
    }
    diffuse(1, vx0, vx, visc, dt, 4);
    diffuse(2, vy0, vy, visc, dt, 4);

    project(vx0, vy0, vx, vy, 4);

    advect(1, vx, vx0, vx0, vy0, dt);
    advect(2, vy, vy0, vx0, vy0, dt);

    project(vx, vy, vx0, vy0, 4);

    diffuse(0, s, density, diff, dt, 4);
    advect(0, density, s, vx, vy, dt);
  }

  void setBnd(int b, List<double> x) {
    for (var i = 1; i < size - 1; i++) {
      x[ix(i, 0)] = b == 2 ? -x[ix(i, 1)] : x[ix(i, 1)];
      x[ix(i, size - 1)] = b == 2 ? -x[ix(i, size - 2)] : x[ix(i, size - 2)];
    }

    for (var j = 1; j < size - 1; j++) {
      x[ix(0, j)] = b == 1 ? -x[ix(1, j)] : x[ix(1, j)];
      x[ix(size - 1, j)] = b == 1 ? -x[ix(size - 2, j)] : x[ix(size - 2, j)];
    }

    x[ix(0, 0)] = 0.5 * (x[ix(1, 0)] + x[ix(0, 1)]);
    x[ix(0, size - 1)] = 0.5 * (x[ix(1, size - 1)] + x[ix(0, size - 2)]);
    x[ix(size - 1, 0)] = 0.5 * (x[ix(size - 2, 0)] + x[ix(size - 1, 1)]);
    x[ix(size - 1, size - 1)] =
        0.5 * (x[ix(size - 2, size - 1)] + x[ix(size - 1, size - 2)]);
  }

  void linSolve(
    int b,
    List<double> x,
    List<double> x0,
    double a,
    double c,
    int iter,
  ) {
    final cRecip = 1.0 / c;
    for (var t = 0; t < iter; t++) {
      for (var j = 1; j < size - 1; j++) {
        for (var i = 1; i < size - 1; i++) {
          x[ix(i, j)] = (x0[ix(i, j)] +
                  a *
                      (x[ix(i + 1, j)] +
                          x[ix(i - 1, j)] +
                          x[ix(i, j + 1)] +
                          x[ix(i, j - 1)])) *
              cRecip;
        }
        setBnd(b, x);
      }
    }
  }

  void diffuse(
    int b,
    List<double> x,
    List<double> x0,
    double diff,
    double dt,
    int iter,
  ) {
    final a = dt * diff * (size - 2) * (size - 2);
    linSolve(b, x, x0, a, 1 + 6 * a, iter);
  }

  void project(
    List<double> velocX,
    List<double> velocY,
    List<double> p,
    List<double> div,
    int iter,
  ) {
    for (var j = 1; j < size - 1; j++) {
      for (var i = 1; i < size - 1; i++) {
        div[ix(i, j)] = -0.5 *
            (velocX[ix(i + 1, j)] -
                velocX[ix(i - 1, j)] +
                velocY[ix(i, j + 1)] -
                velocY[ix(i, j - 1)]) /
            size;
        p[ix(i, j)] = 0;
      }
    }
    setBnd(0, div);
    setBnd(0, p);
    linSolve(0, p, div, 1, 6, iter);

    for (var j = 1; j < size - 1; j++) {
      for (var i = 1; i < size - 1; i++) {
        velocX[ix(i, j)] -= 0.5 * (p[ix(i + 1, j)] - p[ix(i - 1, j)]) * size;
        velocY[ix(i, j)] -= 0.5 * (p[ix(i, j + 1)] - p[ix(i, j - 1)]) * size;
      }
    }
    setBnd(1, velocX);
    setBnd(2, velocY);
  }

  void advect(
    int b,
    List<double> d,
    List<double> d0,
    List<double> velocX,
    List<double> velocY,
    double dt,
  ) {
    double i0, i1, j0, j1;

    final dtx = dt * (size - 2);
    final dty = dt * (size - 2);

    double s0, s1, t0, t1;
    double tmp1, tmp2, x, y;

    final nDouble = (size - 2).toDouble();

    for (var j = 1, jdouble = 1; j < size - 1; j++, jdouble++) {
      for (var i = 1, idouble = 1; i < size - 1; i++, idouble++) {
        tmp1 = dtx * velocX[ix(i, j)];
        tmp2 = dty * velocY[ix(i, j)];
        x = idouble - tmp1;
        y = jdouble - tmp2;

        if (x < 0.5) x = 0.5;
        if (x > nDouble + 0.5) x = nDouble + 0.5;
        i0 = x.floor().toDouble();
        i1 = i0 + 1.0;
        if (y < 0.5) y = 0.5;
        if (y > nDouble + 0.5) y = nDouble + 0.5;
        j0 = y.floor().toDouble();
        j1 = j0 + 1.0;

        s1 = x - i0;
        s0 = 1.0 - s1;
        t1 = y - j0;
        t0 = 1.0 - t1;

        final i0i = i0.toInt();
        final i1i = i1.toInt();
        final j0i = j0.toInt();
        final j1i = j1.toInt();

        d[ix(i, j)] = s0 * (t0 * d0[ix(i0i, j0i)] + t1 * d0[ix(i0i, j1i)]) +
            s1 * (t0 * d0[ix(i1i, j0i)] + t1 * d0[ix(i1i, j1i)]);
      }
    }
    setBnd(b, d);
  }
}
