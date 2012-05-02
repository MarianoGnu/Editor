/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * drawingarea_tile_palette.vala
 * Copyright (C) EasyRPG Project 2011-2012
 *
 * EasyRPG is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * EasyRPG is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * The tile palette DrawingArea.
 */
public class TilePaletteDrawingArea : Gtk.DrawingArea {
////private Cairo.ImageSurface surface_lower_tiles;
////private Cairo.ImageSurface surface_upper_tiles;
////private GLib.HashTable<int, Cairo.ImageSurface> autotiles;
	private LayerType current_layer;
	private Tileset tileset;

	/**
	 * Builds the tile palette DrawingArea.
	 */
	public TilePaletteDrawingArea () {
		this.add_events(
			Gdk.EventMask.BUTTON_PRESS_MASK |
			Gdk.EventMask.BUTTON1_MOTION_MASK
		);

		this.set_size_request (192, -1);
	}

	/**
	 * Sets a tileset.
	 */
	public void set_tileset (Tileset tileset) {
		this.tileset = tileset;
	}

	/**
	 * Manages the reactions to the layer change.
	 * 
	 * Displays the correct palette for the selected layer.
	 */
	public void set_layer (LayerType layer) {
		this.current_layer = layer;

		// Update the DrawingArea size
		switch (layer) {
			case LayerType.LOWER:
				this.set_size_request (
					this.tileset.get_lower_tiles ().get_width () * 2,
					this.tileset.get_lower_tiles ().get_height () * 2
				);
				break;
			case LayerType.UPPER:
			case LayerType.EVENT:
				this.set_size_request (
					this.tileset.get_upper_tiles ().get_width () * 2,
					this.tileset.get_upper_tiles ().get_height () * 2
				);
				break;
			default:
				return;
		}

		// Redraw the DrawingArea
		this.queue_draw ();
	}

	public void load_tileset (string tileset_file) {
		// Instance a new Tileset
		this.tileset = new Tileset (tileset_file);

		// Signal connection
		this.draw.connect (on_draw);
		this.button_press_event.connect (on_button_press);
		this.motion_notify_event.connect (on_button_motion);
	}

	/**
	 * Clears the DrawingArea.
	 */
	public void clear () {
		// Clear the tileset
		this.tileset.clear ();
		this.tileset = null;

		// Make sure it keeps the correct size
		this.set_size_request (192, -1);

		// Redraw the DrawingArea and don't react anymore to the draw signal	
		this.queue_draw ();
		this.draw.disconnect (on_draw);

		// Do not react anymore to the mouse signals
		this.button_press_event.disconnect (on_button_press);
		this.motion_notify_event.disconnect (on_button_motion);
	}

	public bool on_button_press (Gdk.EventButton event) {
		Rect selected_rect = this.tileset.get_selected_rect ();

		selected_rect.set_values(
			((int) event.x) / 32,
			((int) event.y) / 32,
			0, 0
		);

		this.queue_draw();
		return true;
	}

	public bool on_button_motion (Gdk.EventMotion event) {
		Rect selected_rect = this.tileset.get_selected_rect ();

		int width  = ((int) event.x) / 32 - selected_rect.x;
		int height = ((int) event.y) / 32 - selected_rect.y;

		if(selected_rect.width != width || selected_rect.height != height) {
			selected_rect.width = width;
			selected_rect.height = height;
			this.queue_draw();
		}

		return true;
	}

	/**
	 * Manages the reactions to the draw signal.
	 * 
	 * Draws the palette according to the active layer.
	 */
	public bool on_draw (Cairo.Context ctx) {
		// The palette must be scaled to 2x (32x32 tile size) 
		ctx.scale (2, 2);

		switch (this.current_layer) {
			case LayerType.LOWER:
				ctx.set_source_surface (this.tileset.get_lower_tiles (), 0, 0);
				break;
			case LayerType.UPPER:
			case LayerType.EVENT:
				ctx.set_source_surface (this.tileset.get_upper_tiles (), 0, 0);
				break;
			default:
				return false;
		}

		// Fast interpolation, similar to nearest-neighbor
		ctx.get_source ().set_filter (Cairo.Filter.FAST);
		ctx.paint ();

		// Mark selected tiles
		ctx.set_source_rgb (1.0,1.0,1.0);
		ctx.set_line_width (1.0);
		Rect s = this.tileset.get_selected_area (16);
		ctx.rectangle ((double) s.x, (double) s.y, (double) s.width, (double) s.height);
		ctx.stroke ();

		return true;
	}

	/**
	 * Returns tile id for a position in the tileset
	 */
	public static int position_to_id (int x, int y) {
		return y * 6 + x + 1;
	}

	/**
	 * Returns the rectangle of selected tiles.
	 */
	public Rect get_selected_rect () {
		return this.tileset.get_selected_rect ();
	}

	/**
	 * Returns the rectangle of selected tiles prepared
	 * for Drawing to Surfaces.
	 */
	public Rect get_selected_area (int tile_size) {
		return this.tileset.get_selected_area (tile_size);
	}
}
