(*
 * Copyright (c) 2013-2019 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

type version = [ `V1 | `V2 ]

module type VERSION = sig
  val io_version : version
end

module type S = sig
  type t
  type path := string

  exception RO_Not_Allowed

  val v : version:version option -> fresh:bool -> readonly:bool -> path -> t
  val name : t -> string
  val clear : ?keep_generation:unit -> t -> unit
  val append : t -> string -> unit
  val set : t -> off:int64 -> string -> unit
  val read : t -> off:int64 -> bytes -> int
  val offset : t -> int64
  val force_offset : t -> int64
  val generation : t -> int64
  val force_generation : t -> int64
  val readonly : t -> bool
  val version : t -> version
  val flush : t -> unit
  val close : t -> unit
  val exists : string -> bool
  val size : t -> int

  val truncate : t -> unit
  (** Sets the length of the underlying IO to be 0, without actually purging the
      associated data. Not supported for stores beyond [`V1], which should use
      {!clear} instead. *)

  val migrate :
    progress:(int64 -> unit) ->
    t ->
    version ->
    (unit, [> `Msg of string ]) result
  (** @raise Invalid_arg if the migration path is not supported. *)

  val read_buffer : chunk:int -> off:int64 -> t -> string
end

module type IO = sig
  module type VERSION = VERSION
  module type S = S

  type nonrec version = version

  val pp_version : version Fmt.t

  exception Invalid_version of { expected : version; found : version }

  module Unix : S

  module Cache : sig
    type ('a, 'v) t = {
      v : 'a -> ?fresh:bool -> ?readonly:bool -> string -> 'v;
    }

    val memoize :
      v:('a -> fresh:bool -> readonly:bool -> string -> 'v) ->
      clear:('v -> unit) ->
      valid:('v -> bool) ->
      (root:string -> string) ->
      ('a, 'v) t
  end
end
