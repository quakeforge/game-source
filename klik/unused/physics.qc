/* THIS DOES NOT WORK. */

/* If you want to try it, give something
   MOVETYPE_FLY and SOLID_BBOX
   touch = physics_touch_bounce;
   think = physics_think_float;
   nextthink = time + 0.1 */

float PHYSICS_ACCEL = 30;
float PHYSICS_EPSILON = -8;
float STOP_EPSILON = 0.1;

void() physics_touch_bounce = {
	local vector dir;
	local float backoff;

	if (!util_solid(other))
		return;

	if (other.mass && self.mass && (other.mass < self.mass)) {
		local float d;
		d = other.mass / self.mass;
		self.velocity = self.velocity + d*other.velocity;
	} else {
		self.velocity = self.velocity + other.velocity;
	}

	/* Ripped from sv_phys.c, loosely */
	dir = normalize(self.velocity);
	traceline(self.origin - dir, self.origin + dir, FALSE, self);
	backoff = dir * trace_plane_normal;
	backoff = backoff * 1.5;
	dir = trace_plane_normal * backoff;
	self.velocity = self.velocity - dir;
};

vector(vector start, vector dir) _dist_to_boundary = {
	local vector hi, lo, mid, lmid;

	lo = start;
	hi = start + dir;
	mid = lo;
	
	do {
		lmid = mid;

		mid = (lo + hi) * 0.5;
		if (pointcontents(mid) == CONTENT_EMPTY)
			hi = mid;
		else
			lo = mid;
	} while (vlen(mid - lmid) > 1.0);
	
	return mid - start;
};

void() physics_think_float = {
	local vector mid;
	local float contents, liquid_bottom, liquid_middle;
	local float spd, mxspd;

	if (self.mdl_think) {
		if (!self.mdl_thought)	self.mdl_think();
		self.mdl_thought = FALSE;
	}

	mxspd = sv_maxspeed * 0.7 * 0.75;

	mid = self.origin + (self.maxs + self.mins) * 0.5;
	contents = pointcontents(self.origin);
	if (contents >= CONTENT_LAVA && contents <= CONTENT_WATER)
		liquid_middle = TRUE;
	else	liquid_middle = FALSE;

	mid_z = self.origin_z + self.mins_z;
	contents = pointcontents(self.origin);
	if (contents >= CONTENT_LAVA && contents <= CONTENT_WATER)
		liquid_bottom = TRUE;
	else	liquid_bottom = FALSE;

	if (self.flags & FL_ONGROUND) {
		if (self.velocity_z < 0)
			self.velocity_z = 0 - self.velocity_z;
	}

	/* Friction */
	spd = vlen(self.velocity);
	if (spd > 0) {
		self.velocity = self.velocity * (1/spd);

		if (self.flags & FL_ONGROUND) spd = spd - sv_friction*0.1;
		else if (liquid_bottom) spd = spd - 3*sv_waterfriction*0.1;

		if (spd <= 0)	self.velocity = '0 0 0';
		else		self.velocity = self.velocity * spd;
	}

	/* "Gravity" */
	if (liquid_middle) {
		if (!(self.flags & FL_INWATER)) {
			if (self.velocity_z < 0 && self.velocity_z >= PHYSICS_EPSILON) {
				self.flags = self.flags | FL_JUMPRELEASED;
				self.velocity_z = 0;
			}

			self.flags = self.flags | FL_INWATER;

			if (self.velocity_z < 0)
				self.velocity = self.velocity * 0.07;
		} else if (self.velocity_z && (self.flags & FL_JUMPRELEASED)) {
			self.flags = self.flags - FL_JUMPRELEASED;
		}

		if (!(self.flags & FL_JUMPRELEASED)) {
			mid = self.origin + (self.maxs + self.mins) * 0.5;
			if (pointcontents(mid + self.velocity) == CONTENT_EMPTY) {
				mid = _dist_to_boundary(mid, self.velocity);
				self.velocity_z = mid_z + self.velocity_z*0.02;
			} else {
			spd = self.velocity_z + PHYSICS_ACCEL * 0.1;
			if (fabs(spd) <= mxspd || self.velocity_z < 0)
				self.velocity_z = spd;
			}
		}
	} else {
		if (!liquid_bottom) {
			self.velocity_z = self.velocity_z - sv_gravity*0.1;
			if (self.flags & FL_INWATER)
				self.flags = self.flags - FL_INWATER;
		}

		if (self.flags & FL_INWATER) {
			mid = self.origin + (self.maxs + self.mins) * 0.5;
			if (pointcontents(mid + self.velocity) == CONTENT_EMPTY) {
				mid = _dist_to_boundary(mid, self.velocity);
				self.velocity_z = mid_z + self.velocity_z*0.02;
			} else {
				spd = self.velocity_z - PHYSICS_ACCEL * 0.1;
				if (fabs(spd) <= mxspd || self.velocity_z > 0)
					self.velocity_z = spd;
			}
		} else {
		spd = self.velocity_z - PHYSICS_ACCEL * 0.1;
		if (fabs(spd) <= mxspd || self.velocity_z > 0)
			self.velocity_z = spd;
		}
	}

	if (self.velocity_x > (0 - STOP_EPSILON) && self.velocity_x < STOP_EPSILON)
		self.velocity_x = 0;
	if (self.velocity_y > (0 - STOP_EPSILON) && self.velocity_y < STOP_EPSILON)
		self.velocity_y = 0;
	if (self.velocity_z > (0 - STOP_EPSILON) && self.velocity_z < STOP_EPSILON)
		self.velocity_z = 0;

	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';

	/* should use sv_mintic, but mdl_think runs at 10Hz */
	self.nextthink = time + 0.1;
};

