if (!variable_instance_exists(id, "tea_managed") || !tea_managed) exit;

// Free up anything this customer was holding
if (!is_undefined(order) && order.state != "done") tea_cancel_order(order);
if (instance_exists(chair) && variable_instance_exists(chair, "taken_by") && chair.taken_by == id) chair.taken_by = noone;